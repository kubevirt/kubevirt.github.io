---
layout: post
author: DirectedSoul
description: Hyper Converged Operator(HCO) on minikube
navbar_active: Blogs
pub-date: Apr 17
pub-year: 2019
category: news
---

**Hyper Converged Operator(HCO) on minikube**

Minikube is a tool that makes it easy to run Kubernetes locally. Minikube runs a single-node Kubernetes cluster inside a VM on your laptop for users looking to try out Kubernetes or develop with it day-to-day. For testing Hyper Converged Operator we will be deploying a single-node K8’s cluster with the name kubevirt-hco. This can be deployed using minikube:

We’ll create a profile for KubeVirt allowing us to define specific settings and to ensure the settings don’t interfere with any configuration you might had already, let’s start by increasing the default memory to 4GiB:

```
minikube config -p kubevirt-hco set memory 4096
```

Now, set the VM driver to KVM2:

```
minikube config -p kubevirt-hco set vm-driver kvm2
```

We’re ready to start the Minikube VM:

```
minikube start -p kubevirt-hco
```

Also, lets make sure your VM’s CPU supports virtualization extensions execute the following command:

```
minikube ssh -p kubevirt-hco "egrep 'svm|vmx' /proc/cpuinfo"
```

If the command doesn’t generate any output, create the following ConfigMap so that KubeVirt uses emulation mode, otherwise skip to the next section:

```
kubectl create configmap kubevirt-config -n kubevirt-hco --from-literal debug.useEmulation=true
```

**Using the HCO on minikube**

Clone the HCO repo here

```
git clone https://github.com/kubevirt/hyperconverged-cluster-operator.git
```

This gives all the necessary go packages and yaml manifests for the next steps.

Lets create a NameSpace for the HCO deployment

```
kubectl create namespace kubevirt-hyperconverged
```

Now switch to the kubevirt-hyperconverged NameSpace

```
kubectl config set-context $(kubectl config current-context) --namespace=kubevirt-hyperconverged
```

Now launch all the CRD’s

```sh
kubectl create -f deploy/converged/crds/hco.crd.yaml
kubectl create -f deploy/converged/crds/kubevirt.crd.yaml
kubectl create -f deploy/converged/crds/cdi.crd.yaml
kubectl create -f deploy/converged/crds/cna.crd.yaml
```

Lets see the yaml file for HCO Custom Resource Definition

```yaml
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: hyperconvergeds.hco.kubevirt.io
spec:
  additionalPrinterColumns:
  - JSONPath: .metadata.creationTimestamp
    name: Age
    type: date
  - JSONPath: .status.phase
    name: Phase
    type: string
  group: hco.kubevirt.io
  names:
    kind: HyperConverged
    plural: hyperconvergeds
    shortNames:
    - hco
    - hcos
    singular: hyperconverged
  scope: Namespaced
  subresources:
    status: {}
  version: v1alpha1
  versions:
  - name: v1alpha1
    served: true
    storage: true
```

Lets create ClusterRoleBindings, ClusterRole , ServerAccounts and Deployments for the operator

```
$ kubectl create -f deploy/converged
```

And after verifying all the above resources we can now finally deploy our HCO custom resource

```
$ kubectl create -f deploy/converged/crds/hco.cr.yaml 
```

We can take a look at the YAML definition of the CustomResource of HCO:

```yaml
---
apiVersion: hco.kubevirt.io/v1alpha1
kind: HyperConverged
metadata:
  name: hyperconverged-cluster
```

After succesfully executing the above commands,we should be now be having a virt-controller pod, HCO pod,and a network-addon pod functional and can be viewed as below

Lets see the deployed pods

```sh
$kubectl get pods
NAME                                               READY   STATUS    RESTARTS   AGE
cdi-apiserver-769fcc7bdf-rv8zt                     1/1     Running   0          5m2s
cdi-deployment-8b64c5585-g7zfk                     1/1     Running   0          5m2s
cdi-operator-c77447cc7-58ld2                       1/1     Running   0          11m
cdi-uploadproxy-8dcdcbff-rddl6                     1/1     Running   0          5m2s
cluster-network-addons-operator-85cd468ff5-xjgds   1/1     Running   0          11m
hyperconverged-cluster-operator-75dd9c96f9-pqvdk   1/1     Running   0          11m
virt-api-7f5bfb4c58-bkbhq                          1/1     Running   0          4m59s
virt-api-7f5bfb4c58-kkvwc                          1/1     Running   1          4m59s
virt-controller-6ccbfb7d5b-m7ljf                   1/1     Running   0          3m49s
virt-controller-6ccbfb7d5b-mbvlv                   1/1     Running   0          3m49s
virt-handler-hqz9d                                 1/1     Running   0          3m49s
virt-operator-667b6c845d-jfnsr                     1/1     Running   0          11m
```

Now, lets take a look at CRD’s which has a cluster-wide scope as seen below:

```sh
$kubectl get crds 
NAME                                                             CREATED AT
cdiconfigs.cdi.kubevirt.io                                       2019-04-17T18:23:37Z
cdis.cdi.kubevirt.io                                             2019-04-17T18:16:18Z
datavolumes.cdi.kubevirt.io                                      2019-04-17T18:23:37Z
hyperconvergeds.hco.kubevirt.io                                  2019-04-17T18:16:02Z
kubevirts.kubevirt.io                                            2019-04-17T18:16:10Z
network-attachment-definitions.k8s.cni.cncf.io                   2019-04-17T18:23:37Z
networkaddonsconfigs.networkaddonsoperator.network.kubevirt.io   2019-04-17T18:16:26Z
virtualmachineinstancemigrations.kubevirt.io                     2019-04-17T18:23:38Z
virtualmachineinstancepresets.kubevirt.io                        2019-04-17T18:23:38Z
virtualmachineinstancereplicasets.kubevirt.io                    2019-04-17T18:23:38Z
virtualmachineinstances.kubevirt.io                              2019-04-17T18:23:38Z
virtualmachines.kubevirt.io                                      2019-04-17T18:23:38Z
```

Also the below deployments

```sh
$kubectl get deployments
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
cdi-apiserver                     1/1     1            1           10m
cdi-deployment                    1/1     1            1           10m
cdi-operator                      1/1     1            1           16m
cdi-uploadproxy                   1/1     1            1           10m
cluster-network-addons-operator   1/1     1            1           16m
hyperconverged-cluster-operator   1/1     1            1           16m
virt-api                          2/2     2            2           9m58s
virt-controller                   2/2     2            2           8m49s
virt-operator                     1/1     1            1           16m
```

**#NOTE:** Here, Once we applied the Custom Resource the operator took care of deploying the actual KubeVirt pods (virt-api, virt-controller and virt-handler), CDI pods(cdi-upload-proxy, cdi-apiserver, cdi-deployment, cdi-operator) and Network add-on pods ( cluster-network-addons-operator).We will need to wait until all of the resources are up and running. This can be done using the command above or by using the command above with the -w flag.
