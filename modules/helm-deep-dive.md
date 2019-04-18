## Helm Deep Dive

### Explore Helm commands

1. Lets add auto-completion to our helm commands:
    ```
    echo "source <(helm completion bash)" >> ~/.bashrc
    bash -l   
    ```

1. We can search for charts:
    ```console
    helm search concourse
    ```

    Output:
    ```console
    NAME                    CHART VERSION   APP VERSION     DESCRIPTION
    stable/concourse        5.1.2           5.0.1           Concourse is a simple and scalable CI system.
    ```

1. Install chart into its own namespace:

    You can either switch namespaces or refer to another namespace in your install command:
    ```console
    helm install stable/concourse --version 5.1.2 --namespace ci --name concourse
    ```

    Output:
    ```console
    NAME:   concourse
    LAST DEPLOYED: Thu Apr 18 06:12:22 2019
    NAMESPACE: ci
    STATUS: DEPLOYED

    RESOURCES:
    ==> v1beta1/RoleBinding
    NAME                AGE
    concourse-web-main  2s
    concourse-worker    2s

    ==> v1beta1/Deployment
    concourse-postgresql  2s
    concourse-web         2s

    ==> v1beta1/PodDisruptionBudget
    concourse-worker  2s

    ==> v1/ConfigMap
    concourse-postgresql  2s
    concourse-worker      2s

    ==> v1/ServiceAccount
    concourse-web     2s
    concourse-worker  2s

    ==> v1/PersistentVolumeClaim
    concourse-postgresql  2s

    ==> v1beta1/ClusterRole
    concourse-web  2s

    ==> v1beta1/Role
    concourse-worker  2s

    ==> v1/Service
    concourse-postgresql  2s
    concourse-web         2s
    concourse-worker      2s

    ==> v1beta1/StatefulSet
    concourse-worker  2s

    ==> v1/Pod(related)

    NAME                                   READY  STATUS             RESTARTS  AGE
    concourse-postgresql-789cb868b6-zpsrr  0/1    Pending            0         1s
    concourse-web-f5dc5d949-t8qt6          0/1    ContainerCreating  0         1s
    concourse-worker-0                     0/1    Pending            0         1s
    concourse-worker-1                     0/1    Pending            0         1s

    ==> v1/Namespace

    NAME            AGE
    concourse-main  2s

    ==> v1/Secret
    concourse-postgresql  2s
    concourse-concourse   2s


    NOTES:

    * Concourse can be accessed:

      * Within your cluster, at the following DNS name at port 8080:

        concourse-web.ci.svc.cluster.local

      * From outside the cluster, run these commands in the same shell:

        export POD_NAME=$(kubectl get pods --namespace ci -l "app=concourse-web" -o jsonpath="{.items[0].metadata.name}")
        echo "Visit http://127.0.0.1:8080 to use Concourse"
        kubectl port-forward --namespace ci $POD_NAME 8080:8080
    * If this is your first time using Concourse, follow the tutorials at https://concourse-ci.org/tutorials.html

    *******************
    ******WARNING******
    *******************

    You are using the "naive" baggage claim driver, which is also the default value for this chart.

    This is the default for compatibility reasons, but is very space inefficient, and should be changed to either "btrfs" (recommended) or "overlay" depending on that filesystem's support in the Linux kernel your cluster is using.

    Please see https://github.com/concourse/concourse/issues/1230 and https://github.com/concourse/concourse/issues/1966 for background.

    *******************
    ******WARNING******
    *******************

    You're using the default "test" user with the default "test" password.

    Make sure you either disable local auth or change the combination to something more secure, preferably specifying a password in the bcrypted form.

    Please see `README.md` for examples.
    ```

    ```
    kubectl -n ci get pods
    ```

    Output:
    ```
    NAME                                    READY     STATUS    RESTARTS   AGE
    concourse-postgresql-789cb868b6-zpsrr   1/1       Running   0          1m
    concourse-web-f5dc5d949-t8qt6           1/1       Running   1          1m
    concourse-worker-0                      1/1       Running   0          1m
    concourse-worker-1                      1/1       Running   0          1m
    ```

1. Upgrade helm version

    Download new version and replace old version.
    ```console
    wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-linux-amd64.tar.gz
    tar zxfv helm-v2.12.0-linux-amd64.tar.gz
    mv linux-amd64/helm bin/
    helm version
    ```

    Output: (Versions of Server and Client are out of sync, think in most cases we want them to be in sync.)
    ```console
    Client: &version.Version{SemVer:"v2.12.0", GitCommit:"d325d2a9c179b33af1a024cdb5a4472b6288016a", GitTreeState:"clean"}
    Server: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
    ```

    Upgrade tiller as well:
    ```console
    helm init --upgrade
    ```

    Output:
    ```shell
    $HELM_HOME has been configured at /home/gcptraining20/.helm.

    Tiller (the Helm server-side component) has been upgraded to the current version.
    Happy Helming!
    ```

    ```console
    helm version
    ```

    Output:
    ```console
    Client: &version.Version{SemVer:"v2.12.0", GitCommit:"d325d2a9c179b33af1a024cdb5a4472b6288016a", GitTreeState:"clean"}
    Error: could not find a ready tiller pod
    ```

    Check on pod:
    ```console
    kubectl get pods -n kube-system
    ```

    Output (Seems to be running, but has a new age)
    ```diff
    NAME                                             READY     STATUS    RESTARTS   AGE
    dns-controller-547884bc7f-jp42s                  1/1       Running   0          5d
    etcd-server-events-master-us-west1-c-jj9t        1/1       Running   0          10d
    etcd-server-master-us-west1-c-jj9t               1/1       Running   0          10d
    kube-apiserver-master-us-west1-c-jj9t            1/1       Running   1          10d
    kube-controller-manager-master-us-west1-c-jj9t   1/1       Running   0          10d
    kube-dns-6b4f4b544c-6tm9d                        3/3       Running   0          5d
    kube-dns-6b4f4b544c-c7tl8                        3/3       Running   0          5d
    kube-dns-autoscaler-6b658bd4d5-bstb5             1/1       Running   0          5d
    kube-proxy-master-us-west1-c-jj9t                1/1       Running   0          10d
    kube-proxy-nodes-6ptn                            1/1       Running   0          5d
    kube-proxy-nodes-vx94                            1/1       Running   0          5d
    kube-scheduler-master-us-west1-c-jj9t            1/1       Running   0          10d
    + tiller-deploy-6d7964547c-pbrp8                   1/1       Running   0          41s
    ```

    ```console
    helm version
    ```

    Output:
    ```console
    Client: &version.Version{SemVer:"v2.12.0", GitCommit:"d325d2a9c179b33af1a024cdb5a4472b6288016a", GitTreeState:"clean"}
    Server: &version.Version{SemVer:"v2.12.0", GitCommit:"d325d2a9c179b33af1a024cdb5a4472b6288016a", GitTreeState:"clean"}
    ```

1. Delete / restore

    Let's list our deployments
    ```console
    helm list
    ```

    Output:
    ```console
    NAME            REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    concourse       1               Thu Apr 18 06:12:22 2019        DEPLOYED        concourse-5.1.2         5.0.1           ci
    myharbor        1               Fri Apr 12 11:51:25 2019        DEPLOYED        harbor-1.0.1            1.7.5           harbor
    nginx-ingress   1               Fri Apr 12 10:07:20 2019        DEPLOYED        nginx-ingress-1.4.0     0.23.0          ingress
    ```

    We will delete a release:
    ```console
    helm delete concourse
    ```

    Output:
    ```console
    These resources were kept due to the resource policy:
    [Namespace] concourse-main

    release "concourse" deleted
    ```

    No longer shows in our list of deployments:
    ```console
    helm list
    ```

    ```console
    NAME            REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    myharbor        1               Fri Apr 12 11:51:25 2019        DEPLOYED        harbor-1.0.1            1.7.5           harbor
    nginx-ingress   1               Fri Apr 12 10:07:20 2019        DEPLOYED        nginx-ingress-1.4.0     0.23.0          ingress
    ```

    We can gather the hist of our release though:
    ```console
    helm history concourse
    ```

    Output:
    ```console
    REVISION        UPDATED                         STATUS  CHART           DESCRIPTION
    1               Thu Apr 18 06:12:22 2019        DELETED concourse-5.1.2 Deletion complete
    ```

    In order to rollback a deleted released we had to upgrade helm from [2.11 to 2.12](https://github.com/helm/helm/pull/4820).

    Rollback release:
    ```console
    helm rollback concourse 1
    ```

    Output:
    ```console
    Rollback was a success! Happy Helming!
    ```

    ```console
    helm list
    ```

    Output:
    ```console
    NAME            REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    concourse       3               Thu Apr 18 06:45:36 2019        DEPLOYED        concourse-5.1.2         5.0.1           ci
    myharbor        1               Fri Apr 12 11:51:25 2019        DEPLOYED        harbor-1.0.1            1.7.5           harbor
    nginx-ingress   1               Fri Apr 12 10:07:20 2019        DEPLOYED        nginx-ingress-1.4.0     0.23.0          ingress
    ```

    If we want to permanently delete release we would use `helm delete --purge <release>` option.

1. Fetching a chart and unpacking it:

    Let's say we don't know where git repo for helm chart is and we want to make some modifications and make it our own.
    ```console
    helm fetch stable/mysql --version 0.15.0 --untar=true --untardir charts
    ```

    Look at our downloaded files:
    ```console
    ls -ltr charts/mysql/
    ```

    Files are there for us to inspect:
    ```console
    total 36
    -rwxr-xr-x 1 gcptraining20 gcptraining20  4449 Apr 18 08:01 values.yaml
    -rwxr-xr-x 1 gcptraining20 gcptraining20   488 Apr 18 08:01 Chart.yaml
    drwx------ 3 gcptraining20 gcptraining20  4096 Apr 18 08:01 templates
    -rwxr-xr-x 1 gcptraining20 gcptraining20 18911 Apr 18 08:01 README.md
    ```

    Also look at popular charts would help you learn some of the interesting technics some of the charts use:
    ```console
    cat charts/mysql/templates/deployment.yaml
    ```

    ```go
    ...
      {{- if .Values.metrics.enabled }}
      - name: metrics
        image: "{{ .Values.metrics.image }}:{{ .Values.metrics.imageTag }}"
        imagePullPolicy: {{ .Values.metrics.imagePullPolicy | quote }}
        {{- if .Values.mysqlAllowEmptyPassword }}
        command: [ 'sh', '-c', 'DATA_SOURCE_NAME="root@(localhost:3306)/" /bin/mysqld_exporter' ]
        {{- else }}
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ template "mysql.secretName" . }}
              key: mysql-root-password
        command: [ 'sh', '-c', 'DATA_SOURCE_NAME="root:$MYSQL_ROOT_PASSWORD@(localhost:3306)/" /bin/mysqld_exporter' ]
        {{- end }}
        ports:
        - name: metrics
          containerPort: 9104
        livenessProbe:
          httpGet:
            path: /
            port: metrics
          initialDelaySeconds: {{ .Values.metrics.livenessProbe.initialDelaySeconds }}
          timeoutSeconds: {{ .Values.metrics.livenessProbe.timeoutSeconds }}
        readinessProbe:
          httpGet:
            path: /
            port: metrics
          initialDelaySeconds: {{ .Values.metrics.readinessProbe.initialDelaySeconds }}
          timeoutSeconds: {{ .Values.metrics.readinessProbe.timeoutSeconds }}
        resources:
    {{ toYaml .Values.metrics.resources | indent 10 }}
      {{- end }}
    ...
    ```

    We can also inpect the chart with the `helm inspect command and gather more info`:
    ```console
    helm inspect stable/mysql --version 0.15.0
    ```

1. Create your own helm chart

    Super cool chart
    ```console
    helm create charts/supercool
    ```

    Lets look at our files:
    ```console
    ls -ltr charts/supercool/
    ```

    Same like one we downloaded but on closer inspection we will see that they are very different:
    ```console
    total 16
    -rw-r--r-- 1 gcptraining20 gcptraining20 1065 Apr 18 08:18 values.yaml
    drwxr-xr-x 3 gcptraining20 gcptraining20 4096 Apr 18 08:18 templates
    -rw-r--r-- 1 gcptraining20 gcptraining20  105 Apr 18 08:18 Chart.yaml
    drwxr-xr-x 2 gcptraining20 gcptraining20 4096 Apr 18 08:18 charts
    ```

    Let's look at chart version:
    ```console
    cat charts/supercool/Chart.yaml
    ```

    Output:
    ```console
    apiVersion: v1
    appVersion: "1.0"
    description: A Helm chart for Kubernetes
    name: supercool
    version: 0.1.0
    ```

    Now lets convert the [Cassandra StatefulSet](stateful_sets.md) to helm chart. Lets just make sure the previous one is delete just in case.
