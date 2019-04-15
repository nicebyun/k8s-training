# Security

## Objectives

* Implement PSP to limit container capabilities

## Prerequisites

* Enable pod security policies (PSP)

---

After CNI install master and nodes did not come back up what is going on?

## Investigate why system not ready

Look for pods:
```shell
kubectl get pods --all-namespaces
```
```console
No resources found.
```

Does docker see anything:
```shell
sudo docker container ls --format '{{ .Names }}'
```
```console
8s_kube-apiserver_kube-apiserver-k8s-master-01_kube-system_def10cc3bf65d7768714c3b4cc7be55f_0
k8s_etcd_etcd-k8s-master-01_kube-system_8a381bd6d4661b9d3b4ff66431414a9f_0
k8s_kube-scheduler_kube-scheduler-k8s-master-01_kube-system_69aa2b9af9c518ac6265f1e8dce289a0_0
k8s_kube-controller-manager_kube-controller-manager-k8s-master-01_kube-system_3428dc2519888dee434108c2d18dc817_0
k8s_POD_kube-apiserver-k8s-master-01_kube-system_def10cc3bf65d7768714c3b4cc7be55f_0
k8s_POD_etcd-k8s-master-01_kube-system_8a381bd6d4661b9d3b4ff66431414a9f_0
k8s_POD_kube-scheduler-k8s-master-01_kube-system_69aa2b9af9c518ac6265f1e8dce289a0_0
k8s_POD_kube-controller-manager-k8s-master-01_kube-system_3428dc2519888dee434108c2d18dc817_0
```

Another view into what docker see's:
```shell
sudo docker ps
```
```console
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
c740625dd474        f1ff9b7e3d6e           "kube-apiserver --au…"   6 minutes ago       Up 6 minutes                            k8s_kube-apiserver_kube-apiserver-k8s-master-01_kube-system_def10cc3bf65d7768714c3b4cc7be55f_0
7d65127730d2        3cab8e1b9802           "etcd --advertise-cl…"   6 minutes ago       Up 6 minutes                            k8s_etcd_etcd-k8s-master-01_kube-system_8a381bd6d4661b9d3b4ff66431414a9f_0
a85f279d2a52        9508b7d8008d           "kube-scheduler --ad…"   6 minutes ago       Up 6 minutes                            k8s_kube-scheduler_kube-scheduler-k8s-master-01_kube-system_69aa2b9af9c518ac6265f1e8dce289a0_0
ada2373f777a        d82530ead066           "kube-controller-man…"   6 minutes ago       Up 6 minutes                            k8s_kube-controller-manager_kube-controller-manager-k8s-master-01_kube-system_3428dc2519888dee434108c2d18dc817_0
d941f27f5324        k8s.gcr.io/pause:3.1   "/pause"                 6 minutes ago       Up 6 minutes                            k8s_POD_kube-apiserver-k8s-master-01_kube-system_def10cc3bf65d7768714c3b4cc7be55f_0
aec8e57e5503        k8s.gcr.io/pause:3.1   "/pause"                 6 minutes ago       Up 6 minutes                            k8s_POD_etcd-k8s-master-01_kube-system_8a381bd6d4661b9d3b4ff66431414a9f_0
0e81a5dfdfb9        k8s.gcr.io/pause:3.1   "/pause"                 6 minutes ago       Up 6 minutes                            k8s_POD_kube-scheduler-k8s-master-01_kube-system_69aa2b9af9c518ac6265f1e8dce289a0_0
14c3447d35ac        k8s.gcr.io/pause:3.1   "/pause"                 6 minutes ago       Up 6 minutes                            k8s_POD_kube-controller-manager-k8s-master-01_kube-system_3428dc2519888dee434108c2d18dc817_0
```

Let's look at events in the kube-system namespace:
```shell
kubectl get events --namespace kube-system
```
```console
LAST SEEN   TYPE      REASON              KIND         MESSAGE
110s        Warning   FailedCreate        ReplicaSet   Error creating: pods "coredns-86c58d9df4-" is forbidden: no providers available to validate pod request
7m17s       Normal    ScalingReplicaSet   Deployment   Scaled up replica set coredns-86c58d9df4 to 2
7m45s       Normal    Pulled              Pod          Container image "k8s.gcr.io/etcd:3.2.24" already present on machine
7m45s       Normal    Created             Pod          Created container
7m44s       Normal    Started             Pod          Started container
7m45s       Normal    Pulled              Pod          Container image "k8s.gcr.io/kube-apiserver:v1.13.0" already present on machine
7m45s       Normal    Created             Pod          Created container
7m44s       Normal    Started             Pod          Started container
7m45s       Normal    Pulled              Pod          Container image "k8s.gcr.io/kube-controller-manager:v1.13.0" already present on machine
7m45s       Normal    Created             Pod          Created container
7m45s       Normal    Started             Pod          Started container
7m34s       Normal    LeaderElection      Endpoints    k8s-master-01_e607209c-21a4-11e9-81d8-42010a8a000e became leader
110s        Warning   FailedCreate        DaemonSet    Error creating: pods "kube-proxy-" is forbidden: no providers available to validate pod request
7m45s       Normal    Pulled              Pod          Container image "k8s.gcr.io/kube-scheduler:v1.13.0" already present on machine
7m45s       Normal    Created             Pod          Created container
7m44s       Normal    Started             Pod          Started container
7m34s       Normal    LeaderElection      Endpoints    k8s-master-01_e6186a79-21a4-11e9-a7a2-42010a8a000e became leader
```

## Default Security Policy

So because of the security policy the pods are not being added to kubernetes, we will need to create a default policy so that items get created, but security will be top of mind.

Create a PSP file called `default-psp-with-rbac.yaml`:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
  name: default
spec:
  allowedCapabilities: []  # default set of capabilities are implicitly allowed
  allowPrivilegeEscalation: false
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  hostIPC: false
  hostNetwork: false
  hostPID: false
  privileged: false
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsNonRoot'
  supplementalGroups:
    rule: 'RunAsNonRoot'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  volumes:
  - 'configMap'
  - 'downwardAPI'
  - 'emptyDir'
  - 'persistentVolumeClaim'
  - 'projected'
  - 'secret'
  hostNetwork: false
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'

---

# Cluster role which grants access to the default pod security policy
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-psp
rules:
- apiGroups:
  - policy
  resourceNames:
  - default
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

# Cluster role binding for default pod security policy granting all authenticated users access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: default-psp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-psp
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:authenticated
```

We need to apply this policy:
```shell
kubectl apply -f default-psp-with-rbac.yaml
```

Typically `Pods` are created by `Deployments`, `ReplicaSets`, not by the user directly. We need to grant permissions for using this policy to the default account.

We are also creating a privileged psp set that allow kube-system to do its role, `privileged-psp-with-rbac.yaml`:
```yaml
# Should grant access to very few pods, i.e. kube-system system pods and possibly CNI pods
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    # See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
  name: privileged
spec:
  allowedCapabilities:
  - '*'
  allowPrivilegeEscalation: true
  fsGroup:
    rule: 'RunAsAny'
  hostIPC: true
  hostNetwork: true
  hostPID: true
  hostPorts:
  - min: 0
    max: 65535
  privileged: true
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  volumes:
  - '*'

---

# Cluster role which grants access to the privileged pod security policy
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: privileged-psp
rules:
- apiGroups:
  - policy
  resourceNames:
  - privileged
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

# Role binding for kube-system - allow nodes and kube-system service accounts - should take care of CNI i.e. flannel running in the kube-system namespace
# Assumes access to the kube-system is restricted
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kube-system-psp
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: privileged-psp
subjects:
# For the kubeadm kube-system nodes
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
# For all service accounts in the kube-system namespace
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:kube-system
```

Apply configuration:
```shell
kubectl apply -f privileged-psp-with-rbac.yaml
```

Now let's watch what is happening:

```shell
kubectl get pods --all-namespaces --output wide --watch
kubectl get nodes
```

Now things seem to be good, but how what did this really give us? Can we now just create whatever prod we want?


Now try to create a priviledged container:

```yaml
kubectl create -f- <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: privileged
  labels:
    app: privileged
spec:
  replicas: 1
  selector:
    matchLabels:
      app: privileged
  template:
    metadata:
      labels:
        app: privileged
    spec:
      containers:
        - name:  pause
          image: k8s.gcr.io/pause
          securityContext:
            privileged: true
EOF
```

`Deployment` creates `ReplicaSet` that in turn creates `Pod`. Let' see the `ReplicaSet` state.

```shell
kubectl get rs -l=app=privileged
```

```console
NAME                    DESIRED   CURRENT   READY     AGE
privileged-6c96db7488   1         0         0         5m
```

No pods created. Why?

```shell
kubectl describe rs -l=app=privileged
```

```console
..
Error creating: pods "privileged-6c96db7488-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
```

Admission controller forbids creating priviledged container as the applied policy states.

What happens if you create pod directly?

```yaml
kubectl create -f- <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged
spec:
  containers:
    - name:  pause
      image: k8s.gcr.io/pause
      securityContext:
        privileged: true
EOF
```

Try it and explain the result. Why did that happen?

Now we will give another app particular policy since it does need some special access.

```shell
kubectl create namespace ingress-nginx
```

```shell
curl -s https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml | sed '/--publish-service/d'  | kubectl apply -f -

kubectl get pods --namespace ingress-nginx --watch

kubectl get all --namespace ingress-nginx
```

Looks like something is not right:
```console
NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-controller   0/1     0            0           4m22s

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-controller-5b56f55ddc   1         0         0       4m22s
```

Let's gather some info:
```shell
kubectl describe deployment nginx-ingress-controller -n ingress-nginx
```

```console
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  5m32s  deployment-controller  Scaled up replica set nginx-ingress-controller-5b56f55ddc to 1
```

So replicaset created, but what is wrong with that?

```shell
kubectl describe replicaset nginx-ingress-controller-5b56f55ddc -n ingress-nginx
```

```console
  Type     Reason        Age                   From                   Message
  ----     ------        ----                  ----                   -------
  Warning  FailedCreate  39s (x16 over 3m23s)  replicaset-controller  Error creating: pods "nginx-ingress-controller-5b56f55ddc-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.capabilities.add: Invalid value: "NET_BIND_SERVICE": capability may not be added spec.containers[0].securityContext.allowPrivilegeEscalation: Invalid value: true: Allowing privilege escalation for containers is not allowed]
```

Lets create policy specific to this application:

```yaml
cat > nginx-ingress-psp-with-rbac.yaml <<EOF
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    # Assumes apparmor available
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
  name: ingress-nginx
spec:
  # See nginx-ingress-controller deployment at https://github.com/kubernetes/ingress-nginx/blob/master/deploy/mandatory.yaml
  # See also https://github.com/kubernetes-incubator/kubespray/blob/master/roles/kubernetes-apps/ingress_controller/ingress_nginx/templates/psp-ingress-nginx.yml.j2
  allowedCapabilities:
  - NET_BIND_SERVICE
  allowPrivilegeEscalation: true
  fsGroup:
    rule: 'MustRunAs'
    ranges:
    - min: 1
      max: 65535
  hostIPC: false
  hostNetwork: false
  hostPID: false
  hostPorts:
  - min: 80
    max: 65535
  privileged: false
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
    ranges:
    - min: 33
      max: 65535
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
    # Forbid adding the root group.
    - min: 1
      max: 65535
  volumes:
  - 'configMap'
  - 'downwardAPI'
  - 'emptyDir'
  - 'projected'
  - 'secret'

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ingress-nginx-psp
  namespace: ingress-nginx
rules:
- apiGroups:
  - policy
  resourceNames:
  - ingress-nginx
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-nginx-psp
  namespace: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx-psp
subjects:
# Lets cover default and nginx-ingress-serviceaccount service accounts
# Could have altered default-http-backend deployment to use the same service acccount to avoid granting the default service account access
- kind: ServiceAccount
  name: default
- kind: ServiceAccount
  name: nginx-ingress-serviceaccount
EOF
```

Now let's apply and see if it makes any difference:

```shell
kubectl apply -f nginx-ingress-psp-with-rbac.yaml

kubectl get pods --namespace ingress-nginx --watch

kubectl describe pod nginx-ingress-controller-5b56f55ddc-rr7gj -n ingress-nginx|less
```
