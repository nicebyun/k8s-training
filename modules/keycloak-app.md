# Keycloak

[Keycloak](https://github.com/keycloak/keycloak) is an Open Source Identity and Access Management solution for modern Applications and Services.

This repository contains the source code for the Keycloak Server, Java adapters and the JavaScript adapter.

## Module Objectives

1. Keycloak Setup
1. Ingress Flow Issues
1. Deployment Issues

---

## Keycloak Setup

1. Deploy Keycloak:

    ![](img/authz-arch-overview.png)

    Create namespace for keycloak and update context
    ```console
    kubectl create ns keycloak
    kubens keycloak
    ```

    Deploy Keycloak Deployment and service
    ```console
    kubectl apply -f keycloak/keycloak.yaml
    ```

    check status
    ```console
    kubectl get all
    ```

    Get service:
    ```console
    kubectl get svc
    ```

    Output:
    ```console
    NAME       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
    keycloak   LoadBalancer   100.68.194.194   35.233.138.161   8080:32334/TCP   2m
    ```

    This is the keycloak service loadBalancer and should not be used to gain access. It is not fronted by https!!
    Explore the service at this stage. Should we now use the service as is?
    ```shell
    echo http://$(kubectl get svc keycloak -ojsonpath='{.status.loadBalancer.ingress[].ip}'):8080
    ```

    Save keycloak variables for later use.
    ```shell
    echo '## Keycloak variables' >> ~/.bashrc
    echo 'export KEYCLOAK_HOST=keycloak.$KUBE_IP.nip.io' >> ~/.bashrc
    echo 'export BACKEND_HOST=backend.$KUBE_IP.nip.io' >> ~/.bashrc
    echo 'export FRONTEND_HOST=frontend.$KUBE_IP.nip.io' >> ~/.bashrc
    bash -l
    ```

    Add Certificate to namespace as secret.
    Remember we have these variables defined in ~/.bashrc
    ```shell
    export CERT_NAME=kube-tls
    kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}
    ```

    Deploy ingress fronted with self signed cert
    ```shell
    cat modules/keycloak-demo/keycloak/keycloak-ingress.yaml | sed "s/KEYCLOAK_HOST/$KEYCLOAK_HOST/" \
    | kubectl apply -f -

    echo https://$KEYCLOAK_HOST
    ```

    The Keycloak admin console should now be opened in your browser. Ignore the warning caused by the self-signed certificate. Login with admin/admin. Create a new realm and import `keycloak/realm.json`.

    The client config for the frontend allows any redirect-uri and web-origin. This is to simplify configuration for the demo. For a production system always use the real URL of the application for the redirect-uri and web-origin.

## Backend with public repo
1. Deploying a backend application that will use keycloak

    We will switch namespace back to default:
    ```console
    kubens default
    ```

    We will build and push our application to our internal harbor instance. If you get error `Get https://core.XXX.XXX.XXX.XXX.nip.io/v2/: x509: certificate signed by unknown authority` please see next step:
    ```shell
    docker build -t ${HARBOR_CORE}/pub/kube-demo-backend modules/keycloak-demo/backend/
    docker push ${HARBOR_CORE}/pub/kube-demo-backend
    ```

    ***ONLY NECESSARY IF ERROR ABOVE***
    ```
    sudo mkdir -p /etc/docker/certs.d/${HARBOR_CORE}/
    sudo cp cert.pem /etc/docker/certs.d/${HARBOR_CORE}/ca.crt    
    ```

    Updating our configuration with our hostname and internal harbor registry:
    ```shell
    cat modules/keycloak-demo/backend/backend.yaml | sed -e "s/KEYCLOAK_HOST/$KEYCLOAK_HOST/" \
    -e "s/HARBOR_CORE/$HARBOR_CORE/" | kubectl apply -f -
    ```

    Checking status of deployment:
    ```console
    kubectl get pods
    ```

    Should look something like this:
    ```console
    NAME                            READY     STATUS    RESTARTS   AGE
    backend-9c969496b-fjsb9         1/1       Running   0          2d
    ```

    We also have to add certificate and key to this namespace
    ```
    kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} -
    ```

    Deploy ingress, get public route and try it out:
    ```shell
    cat modules/keycloak-demo/backend/backend-ingress.yaml | sed "s/BACKEND_HOST/$BACKEND_HOST/" | \
    kubectl apply -f -

    echo https://$BACKEND_HOST/public
    ```

    You can now open a browser and hit the public backend or use curl:
    ```
    curl -L https://$BACKEND_HOST/public -k ;echo
    ```

    Output:
    ```json
    {"message":"public"}
    ```

## Frontend with private repo
1. Deploying fronted application for our backend.
    Docker build and push:
    ```shell
    docker build -t ${HARBOR_CORE}/pub/kube-demo-frontend modules/keycloak-demo/frontend
    docker push ${HARBOR_CORE}/pub/kube-demo-frontend
    ```

    Deploy app after updating variables:
    ```
    cat modules/keycloak-demo/frontend/frontend.yaml | sed -e "s/KEYCLOAK_HOST/$KEYCLOAK_HOST/" \
    -e "s/BACKEND_HOST/$BACKEND_HOST/" -e "s/HARBOR_CORE/$HARBOR_CORE/" | \
    kubectl apply -f -
    ```

    Once deployment is up and running we can add ingress:
    ```
    cat modules/keycloak-demo/frontend/frontend-ingress.yaml | sed "s/FRONTEND_HOST/$FRONTEND_HOST/" | \
    kubectl apply -f -

    echo https://$FRONTEND_HOST
    ```

    The frontend application should now be opened in your browser. Login with joe/pass. You should be able to invoke public and invoke secured, but not invoke admin. To be able to invoke admin go back to the Keycloak admin console and add the `admin` role to the user `joe`.

1. Demo Integration:


1. Change Frontend to private repo.
  - Update from `${HARBOR_CORE}/pub/kube-demo-frontend to ${HARBOR_CORE}/priv/kube-demo-frontend`
  - https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
