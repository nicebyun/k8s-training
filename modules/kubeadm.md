# Installing a Kubernetes Cluster on Google Cloud Platform (GCP) with Kubeadm

Kubeadm is a tool built to provide `kubeadm init` and `kubeadm join` as best-practice “fast paths” for creating Kubernetes clusters.

We wanted to show our students another way to deploying kubernetes and next two security topics worked well with this setup. We will be demonstrating PodSecurityPolicy and using a CNI that allows Network policies so you can approach least privilege at different layers of your security posture.

## Prerequisites

* kubeadm to create the cluster [Kubeadm Overview](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/)
* Google Cloud SDK [gcloud tools documentation](https://cloud.google.com/sdk/docs/) to create instances
* Canal CNI plugin [Calico for Policy/Flannel for Networking](https://docs.projectcalico.org/v3.5/getting-started/kubernetes/installation/flannel)


### Exercise 1: Spin up instances we will use for Kubernetes cluster

1. Using gcloud to spin up systems.

   We will create one master and two nodes for our cluster:

   ```shell
   cd ~/k8s-training-jan2019
   
   gcloud compute instances create k8s-master-01 --zone=us-west1-c --machine-type=n1-standard-4 --subnet=default \
     --image=ubuntu-1604-xenial-v20190122a --image-project=ubuntu-os-cloud --boot-disk-size=20GB --boot-disk-type=pd-standard \
     --boot-disk-device-name=k8s-master-01 --metadata-from-file startup-script=modules/scripts/k8s-user-data.sh \
     --scopes=https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only \
     --tags=k8s-master --async

   for i in `seq 1 2`; do
     gcloud compute instances create k8s-node-0${i} --zone=us-west1-c --machine-type=n1-standard-4 --subnet=default \
         --image=ubuntu-1604-xenial-v20190122a --image-project=ubuntu-os-cloud --boot-disk-size=50GB --boot-disk-type=pd-standard \
         --boot-disk-device-name=k8s-node-0${1} --metadata-from-file startup-script=modules/scripts/k8s-user-data.sh --async
   done
   ```

   You will note that we have included a startup script for the systems to prepare them to be a part of the cluster and have all the needed components ready.

   Take a look at [k8s-user-dasta.sh](scripts/k8s-user-data.sh)

   Further Reference please see [Create Cluster with Kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/).

1. Copy files to master and setup kubelet auto-complete

   Copy our repository to master:

   ```shell
   cd
   gcloud compute scp --recurse k8s-training-jan2019 k8s-master-01:
   ```

   Setup auto-complete for kubectl:

   ```shell
   gcloud compute ssh k8s-master-01

   echo "source <(kubectl completion bash)" >> ~/.bashrc
   bash -l      
   ```

1. Create kubeadm config that allows PodSecurityPolicy and has some other customizations

   In order to enable pod security we have to use a config file because not everything is exposed by command line flag. GoDoc for [kubeadm api](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1). Also you can see [Using Pod Security with kubeadm](https://pmcgrath.net/using-pod-security-policies-with-kubeadm).

   So how do we even begin creating a config that kubeadm can use? Well kubeadm has a command line option to get you started. Let's use it.

   ```shell
   kubeadm config print init-defaults
   ```

   I have prepared a config that has been tested, and we will make the necessary modifications and then will compare with defaults. We will be gathering the machine IP, and generating a join token that will be displayed after initialization of master is complete.
   ```shell
   sed -i -e "s/<TOKEN>/$(kubeadm token generate)/" -e "s/<APIIP>/$(awk '/k8s-master/ {print $1}' /etc/hosts)/" k8s-training-jan2019/modules/yaml/kubeadm-config.yaml
   ```

   To compare we will generate to file and diff the files:
   ```shell
   kubeadm config print init-defaults > config-defaults.yaml
   diff config-defaults.yaml k8s-training-jan2019/modules/yaml/kubeadm-config.yaml
   ```

   Notable differences are things generated during sed replacement, plus we added PodSecurityPolicy plugin, changed the cluster name, and added pod subnet. To look at more items that can be adjusted please look at GoDoc for [kubeadm api](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1).

1. Now we apply the configuration and will join nodes as well

   Run initialization with config:
   ```shell
   sudo kubeadm init --config k8s-training-jan2019/modules/yaml/kubeadm-config.yaml
   ```    

   Once complete you will see a set of instructions to copy admin.conf to setup kubectl to be able to talk to kubernetes. Go ahead and run these:
   ```shell
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

   Let's see what we have so far by checking what notes we have:
   ```shell
   kubectl get nodes

   ```

   ```console
   NAME            STATUS     ROLES    AGE    VERSION
   k8s-master-01   NotReady   master   114s   v1.13.2
   ```

   Lets use the next instructions to join node via kubeadm that looks like this(you will be running this on k8s-node-01 and k8s-node-02):
   ```shell
   sudo kubeadm join 10.138.0.14:6443 --token gzg4et.1llq15fq6ejosg6f --discovery-token-ca-cert-hash sha256:3c08138f888a9d78e073d82a3c92284f8dd43e174849aca2684f318f1df3af87
   ```

   So to do that lets use the `+` button to "Add Cloud Shell session" on the cloud shell window by the top of screen:

   ```shell
   gcloud compute ssh k8s-node-01
   ```

   We will take advantage of tmux and split the screen by typing `ctrl-b %` then ssh in to other machine:

   ```shell
   gcloud compute ssh k8s-node-02
   ```

   Next we will sync the two panes by using following method:
   Type `ctrl-b :` and then type at bottom of yellow prompt: `setw synchronize-panes`

   Now with both machines synced we run the kubeadm join command that you got from your master:
   ```shell
   sudo kubeadm join 10.138.0.14:6443 --token gzg4et.1llq15fq6ejosg6f --discovery-token-ca-cert-hash sha256:3c08138f888a9d78e073d82a3c92284f8dd43e174849aca2684f318f1df3af87
   ```

   Now go back to the session with master running and run `kubectl get nodes` again:

   ```console
   NAME            STATUS     ROLES    AGE   VERSION
   k8s-master-01   NotReady   master   17m   v1.13.2
   k8s-node-01     NotReady   <none>   17s   v1.13.2
   k8s-node-02     NotReady   <none>   17s   v1.13.2
   ```

1. We will also be labeling nodes manually at this point as well. This becomes important for controllerManager as it checks if nodes have these annotations during volume creation and attaching to nodes. 

   ```shell
   kubectl label node k8s-node-01 failure-domain.beta.kubernetes.io/region=us-west1 failure-domain.beta.kubernetes.io/zone=us-west1-c
   kubectl label node k8s-node-02 failure-domain.beta.kubernetes.io/region=us-west1 failure-domain.beta.kubernetes.io/zone=us-west1-c
   ```

1. Now lets setup our Container Network Interfaces (CNI)

   After testing what will work at without too much trouble, and wont produce intermittent results, we landed on Canal.

   Here is how to install the latest at the time of this writing:
   ```shell
   kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
   kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/canal/canal.yaml
   ```

   Typically at this point the master and nodes would turn from `NotReady` to `Ready` state. Why do you think systems are not flipping to good state? Well we will be taking a look at this very question next.

---

Next: [Pod and Network Security](security.md)
