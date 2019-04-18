Extras
=====================

These extra items should help us navigate lab faster.

1. Get kube ops view
    ```console
    git clone -b 0.11 https://github.com/hjacobs/kube-ops-view.git
    cd kube-ops-view
    ```

1. Deploy kube-ops-view
    ```console
    kubectl apply -f deploy
    ```


    ```console
    kubectl proxy
    ```
    Redirect brower to http://localhost:8001/api/v1/namespaces/default/services/kube-ops-view/proxy/
