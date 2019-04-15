Installing Nginx Ingress
=====================

[nginx-ingress](https://github.com/kubernetes/ingress-nginx) is an Ingress controller that uses ConfigMap to store the nginx configuration. This setup allows you to use one loadBalancer and pass thru traffic based on the host headers. Greatly improving reuse and usability of resources.

To use, add the kubernetes.io/ingress.class: nginx annotation to your Ingress resources.

1. Create ingress controller namespace and deploy

    ## Create ingress namespace and create ingress
    Deploy nginx controller
    https://cloud.google.com/community/tutorials/nginx-ingress-gke

    ```
    kubectl create ns ingress
    kubens ingress
    helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true
    ```

    We will need to take note of configuration we will be able to apply to our ingress instances, and of loadBalancer IP.

    If you want to watch as the ingress gets bound to IP run this command:
    ```console
    kubectl --namespace ingress get services -o wide -w nginx-ingress-controller
    ```
    #######
    NOTES:
    The nginx-ingress controller has been installed.
    It may take a few minutes for the LoadBalancer IP to be available.
    You can watch the status by running 'kubectl --namespace ingress get services -o wide -w nginx-ingress-controller'

    An example Ingress that makes use of the controller:

      apiVersion: extensions/v1beta1
      kind: Ingress
      metadata:
        annotations:
          kubernetes.io/ingress.class: nginx
        name: example
        namespace: foo
      spec:
        rules:
          - host: www.example.com
            http:
              paths:
                - backend:
                    serviceName: exampleService
                    servicePort: 80
                  path: /
        # This section is only required if TLS is to be enabled for the Ingress
        tls:
            - hosts:
                - www.example.com
              secretName: example-tls

    If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

      apiVersion: v1
      kind: Secret
      metadata:
        name: example-tls
        namespace: foo
      data:
        tls.crt: <base64 encoded cert>
        tls.key: <base64 encoded key>
      type: kubernetes.io/tls
    #####

1. Create secret key and wildcard Cert:

    ```
    ## ingress
    echo "## ingress and cert variables" >> ~/.bashrc
    echo "export KUBE_IP=$(kubectl -n ingress get svc nginx-ingress-controller -ojsonpath='{.status.loadBalancer.ingress[].ip}')" >> ~/.bashrc
    echo 'export KEY_FILE=key.pem' >> ~/.bashrc
    echo -e 'export CERT_FILE=cert.pem\n' >> ~/.bashrc
    bash -l

    HOST="\*.$KUBE_IP.nip.io"

    # generate self signed
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"
    ```
