# Deployments and Health Checks

## Module Objectives

- Define custom health checks and liveness probes
- Use horizontal pod autoscaler
- Use jobs and cronJobs to schedule task execution

---

## Define Custom Health Checks and Liveness Probes

By default, Kubernetes assumes that a Pod is ready to accept requests as soon as its container is ready and the main process starts running. Once this condition is met, Kubernetes Services will redirect traffic to the Pod. This can cause problems if the application needs some time to initialize. Let's reproduce this behavior.

1. We will deploy the sample-app manually to default namespace and make some modifications to test some things out.

    Copy `k8s/production` to `k8s/hpa`:

    ```shell
    cd ~/k8s-training-jan2019/sample-app/
    cp -a k8s/production k8s/hpa
    ```

    We will be gathering the latest `master` tag from the image gcr repo, like this one `gcr.io/gcptraining2-217368/gceme:master.1`. If you want to see the output please run gcloud commands on their own.

    ```shell
    IMG=$(gcloud container images list 2>&1|egrep "^gcr.*.gceme$")
    IMG_VERSION=$(gcloud container images list-tags $IMG |egrep -v DIGEST|head -1|awk '{print $2}')
    sed -i.bak "s#REPLACE_WITH_IMAGE#${IMG}:${IMG_VERSION}#" ./k8s/hpa/*.yaml
    kubectl create secret generic mysql --from-literal=password=root
    kubectl apply -f k8s/hpa/
    kubectl apply -f k8s/services/
    ```

    Now we have our sample app running on our default namespace, and their is no conflict.

    ```console
    kubectl get pods

    NAME                                         READY     STATUS    RESTARTS   AGE
    gceme-backend-production-5bf9cb4575-chv6g    1/1       Running   0          4m
    gceme-backend-production-5bf9cb4575-tnmvk    1/1       Running   0          4m
    gceme-frontend-production-57bcd5c8c4-4zchm   1/1       Running   0          4m
    gceme-frontend-production-57bcd5c8c4-qmdzz   1/1       Running   0          4m
    gceme-frontend-production-57bcd5c8c4-tc7t6   1/1       Running   0          4m
    gceme-frontend-production-57bcd5c8c4-wc2lt   1/1       Running   0          4m
    mysql-5bfd5f74dd-bgwtt                       1/1       Running   0          1h
    ```

    Go to the external IP:

    ```shell
    kubectl get svc gceme-frontend
    ```

    ```console
    curl <EXTERNAL-IP>

    <!doctype html>
    <html>
      <head>
        <script
          src="https://code.jquery.com/jquery-3.3.1.min.js"
          integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8="
          crossorigin="anonymous"></script>

        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.0/css/materialize.min.css">
    ...
    ```

1. Now Add `-delay=60` to the `command` property in the `k8s/hpa/backend-production.yaml` and also lets comment out readinessProde. Once you finish the edits apply the changes.

    ```yaml
          #readinessProbe:
          #  httpGet:
          #    path: /healthz
          #    port: 8080
     ```


1. Open the app in the web browser. You should see the following error for about a minute:

    ```
    Error: Get http://backend:8080: dial tcp 10.51.249.99:8080: connect: connection refused
    ```

    Now let's fix this problem by uncommenting the `readinessProbe`. We can also use livenessProbe.

    The `readinessProbe` and `livenessProbe` are used by Kubernetes to check the health of the containers in a Pod. The probes can check either HTTP endpoints or run shell commands to determine the health of a container. The difference between readiness and liveness probes is subtle, but important.

    If an app fails a `livenessProbe`, kubernetes will restart the container.

    > Caution: A misconfigured `livenessProbe` could cause deadlock for an application to start. If an application takes more time than the probe allows, then the livenessProbe will always fail and the app will never successfully start. See [this document](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for how to adjust the timing on probes.

    If an app fails a `readinessProbe`, Kubernetes will consider the container unhealthy and send traffic to other Pods.

    > Note: Unlike liveness, the Pod is not restarted.

    For this exercise, we will use only a `readinessProbe`.

1. Uncomment the readiness probe and apply.

    Pods gceme-backend-production-5967bfbfd7 are new but are not ready so have not taken over. Once they are ready then old version start to terminate.

    ```console
    kubectl get pods
    NAME                                         READY     STATUS    RESTARTS   AGE
    gceme-backend-production-5967bfbfd7-6qgwc    0/1       Running   0          59s
    gceme-backend-production-5967bfbfd7-whm5g    0/1       Running   0          59s
    gceme-backend-production-7f87d5c95-55n5t     1/1       Running   0          3m
    gceme-frontend-production-8684d5598f-g59tn   1/1       Running   0          9m
    gceme-frontend-production-8684d5598f-p6grn   1/1       Running   0          8m
    gceme-frontend-production-8684d5598f-tqgj6   1/1       Running   0          9m
    gceme-frontend-production-8684d5598f-twbr4   1/1       Running   0          8m
    mysql-5bfd5f74dd-bgwtt                       1/1       Running   0          4h

    gcptraining2@cloudshell:~/k8s-training-jan2019-after-course-updates/sample-app (gcptraining2-217368)$ kubectl get pods
    NAME                                         READY     STATUS        RESTARTS   AGE
    gceme-backend-production-5967bfbfd7-6qgwc    0/1       Running       0          1m
    gceme-backend-production-5967bfbfd7-whm5g    1/1       Running       0          1m
    gceme-backend-production-7f87d5c95-55n5t     1/1       Terminating   0          3m
    ```


1. Run `watch kubectl get pod` to see how Kubernetes is rolling out your Pods. This time it will do it much slower, making sure that previous Pods are ready before starting a new set of Pods.

## Use Horizontal Autoscaler

Now we will use the horizontal autoscaler to automatically set the number of backend instances based on the current load.

1. Scale the number of backend instances to 1.

    > Note: You can either modify `k8s/hpa/backend-production.yaml` file and apply changes or use `kubectl scale` command.

1. Apply autoscaling to the backend Deployment.

    ```shell
    kubectl autoscale deployment gceme-backend-production --cpu-percent=50 --min=1 --max=3
    ```

1. Check the status of the autoscaler.

    ```shell
    kubectl get hpa
    ```

    ```
    NAME      REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
    backend   Deployment/backend   0%/50%    1         3         1          1m
    ```

    Setting the hpa will also effect current pods, and will scale down `kubectl get pods`:

    ```
    NAME                                         READY     STATUS        RESTARTS   AGE
    gceme-backend-production-5967bfbfd7-6qgwc    1/1       Terminating   0          21m
    gceme-backend-production-5967bfbfd7-whm5g    1/1       Running       0          21m
    gceme-frontend-production-8684d5598f-g59tn   1/1       Running       0          29m
    gceme-frontend-production-8684d5598f-p6grn   1/1       Running       0          28m
    gceme-frontend-production-8684d5598f-tqgj6   1/1       Running       0          29m
    gceme-frontend-production-8684d5598f-twbr4   1/1       Running       0          28m
    mysql-5bfd5f74dd-bgwtt                       1/1       Running       0          4h
    ```

1. Exec inside the Pod.

    ```shell
    kubectl exec -it <backend-pod-name> bash
    ```

1. Install `stress` and use the following command to generate some load.

    ```shell
    apt-get update & apt-get install stress
    stress --cpu 60 --timeout 200
    ```

1. In a different terminal window watch the autoscaler status. You may have to install stress on the new pod and stress that one too.

    ```shell
    watch kubectl get hpa
    ```

    ```
    NAME      REFERENCE            TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
    backend   Deployment/backend   149%/50%   1         3         3          13m
    ```

    Wait until the autoscaler scales the number of `backend` Pods to 3.

1. Save the autoscaler definition as a Kubernetes object and examine its content.

    ```shell
    kubectl get hpa -o yaml > k8s/hpa/autoscaler.yaml
    ```

## Use Jobs and CronJobs to Schedule Task Execution

Sometimes there is a need to run one-off tasks. You can use Pods to do that, but if the task fails nobody will be able to track that and restart the Pod. Kubernetes Jobs provide a better alternative to run one-off tasks. Jobs can be configured to retry failed task several times. If you need to run a Job on a regular basis you can use CronJobs. Now let's create a CronJob that will do a database backup for us.

1. Save the following file as `k8s/hpa/backup.yaml` and apply the changes.

    ```yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: backup
    spec:
      schedule: "*/1 * * * *"
      jobTemplate:
        spec:
          backoffLimit: 2
          template:
            spec:
              containers:
              - name: backup
                image: mysql:5.6
                command: ["/bin/sh", "-c"]
                args:
                - mysqldump -h db -u root -p$MYSQL_ROOT_PASSWORD sample_app
                env:
                - name: MYSQL_ROOT_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: mysql
                      key: password
              restartPolicy: OnFailure
    ```

    This creates a CronJob that runs each minute. `backoffLimit` is set to 2 so the job will be retried 2 times in case of failure. The job runs the `mysqldump` command that prints the contents of the `sample_app` database to stdout. This will be available in the Pod logs. (And yes, I know that Pod logs is the worst place to store a database backup 😄  )

1. Get the cronjob status.

    ```yaml
    kubectl get cronjob backup
    ```

    ```
    NAME      SCHEDULE      SUSPEND   ACTIVE    LAST SCHEDULE   AGE
    backup    */1 * * * *   False     0         2m              25m
    ```

1. After 1 minute a` backup` Pod will be created, if you list the Pods you should see the backup completed.

    ```shell
    watch kubectl get pod
    ```

    ```
    NAME                        READY     STATUS      RESTARTS   AGE
    backend-dc656c878-v5fh7     1/1       Running     0          3m
    backup-1543535520-ztrpf     0/1       Completed   0          1m
    db-77df47c5dd-d8zc2         1/1       Running     0          1h
    frontend-654b5ff445-bvf2j   1/1       Running     0          1h
    ```

1. View the `backup` Pod logs and make sure that backup was completed successfully.

    ```shell
    kubectl logs <backup-pod-name>
    ```

1. Delete the CronJob.

    ```shell
    kubectl delete cronjob backup
    ```
