Install Helm
=====================

Helm is a package manager for Kubernetes. You will use it to install Jenkins.

Helm packages called Charts contain application itself, metadata and deployment automation scripts. There is a [repository](https://github.com/helm/charts) with Charts for the most common products including Jenkins.

Helm has two parts: `helm` CLI and Tiller Kubernetes service.

Install Helm into `$HOME` directory as Cloud Shell erases everything else on disk between restarts.

1. Download the Helm binary

    ```
    wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
    ```

1. Extract Helm client

    ```
    tar zxfv helm-v2.11.0-linux-amd64.tar.gz
    cp linux-amd64/helm ~/bin/
    ```

1. Grant `cluster-admin` role to your account

    ```shell
    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
    ```

1. Create `tiller` service account with the `cluster-admin` role

    ```
    kubectl create serviceaccount tiller --namespace kube-system
    kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    ```

1. Deploy Tiller

    ```
    helm init --service-account=tiller
    helm update
    ```

1. Verify that both parts of Helm are up and running

    ```
    helm version
    Client: &version.Version{SemVer:"v2.11.0", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
    Server: &version.Version{SemVer:"v2.11.0", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
    ```

    ```
    kubectl get deployments -n kube-system
    NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    dns-controller        1         1         1            1           4d
    kube-dns              2         2         2            2           4d
    kube-dns-autoscaler   1         1         1            1           4d
    tiller-deploy         1         1         1            1           2m
    ```
