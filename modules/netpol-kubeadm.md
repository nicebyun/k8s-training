# Security

## Objectives

- Implement network policy to limit interactions between pods

## Prerequisites

- Use CNI that allows for network policy

---

## Network Policy egress

Let's see how to use network policy for blocking the external traffic for a `Pod`

Create file called `deny-egress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: foo-deny-egress
spec:
  podSelector:
    matchLabels:
      app: foo
  policyTypes:
  - Egress
  egress:
  # allow DNS resolution
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

```shell
kubectl apply -f deny-egress.yaml
```

This file blocks all the outgoing traffic except DNS resolution.

Now start the pod that matches label `app=foo`

```shell
kubectl run --rm --restart=Never --image=alpine -i -t -l app=foo test -- ash
```

In container run:
```shell
wget --timeout 1 -O- http://www.example.com
```

```console
Connecting to www.example.com (93.184.216.34:80)
wget: download timed out
```

You see the name resolution works fine but external connections are dropped.

Now remove the `-l app=foo` and see what happens.

## Network policy ingress

Now we will create a service and set policy that will restrict access to it.

Create nginx and expose the service:

```shell
kubectl run nginx --image=nginx --replicas=2
kubectl expose deployment nginx --port=80

kubectl get svc,pod
```

Execute a pod and see if you can connect:
```shell
kubectl run busybox --rm -ti --image=busybox /bin/sh
```

```console
wget --spider --timeout=1 nginx

Connecting to nginx (10.104.90.248:80)
```

Now create the policy to restrict access:

```yaml
cat > nginx-policy.yaml <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"
EOF
```

```
kubectl apply -f nginx-policy.yaml
```

Now again try to connect via pod:

```shell
kubectl run busybox --rm -ti --image=busybox /bin/sh
```

```console
/ # wget --spider --timeout=1 nginx
Connecting to nginx (10.100.0.16:80)
wget: download timed out
/ #
```

Now try with pod we have allowed via label:

```shell
kubectl run busybox --rm -ti --labels="access=true" --image=busybox /bin/sh
```

```console
/ # wget --spider --timeout=1 nginx
Connecting to nginx (10.109.50.139:80)
/ #
```
