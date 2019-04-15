Adding Private Key
=====================

I am providing you the private key used to access repo via ssh.

1. Download key
    ```console
    wget -O ~/.ssh/id_rsa https://drive.google.com/uc?id=15uad8cAFBUCRJBIldRVpyYm13I-ipdHh&export=download
    ```

1. Update permissons
    ```console
    chmod 600 .ssh/id_rsa
    ```

1. Checkout code

Clone the lab repository in your cloud shell, then `cd` into that directory:

    ```console
    git clone git@github.com:cxhercules/k8s-training.git k8s-training
    ```

    ```console
    cd k8s-training
    ```
