---
layout: post
author: DirectedSoul
description: Hyper Converged Operator on OCP4 and K8s(HCO) 
navbar_active: Blogs
pub-date: May 08
pub-year: 2019
category: news
---

## Operators-Definition

## What is an Operator after all?

Operators are a design pattern made public in a 2016 [CoreOS](https://coreos.com/blog/introducing-operators.html) blog post. The goal of an Operator is to put operational knowledge into software. Previously this knowledge only resided in the minds of administrators, various combinations of shell scripts or automation software like Ansible. It was outside of your Kubernetes cluster and hard to integrate. With Operators, CoreOS changed that.

Operators implement and automate common Day-1 (installation, configuration, etc) and Day-2 (re-configuration, update, backup, failover, restore, etc.) activities in a piece of software running inside your Kubernetes cluster, by integrating natively with Kubernetes concepts and APIs. We call this a Kubernetes-native application. With Operators you can stop treating an application as a collection of primitives like Pods, Deployments, Services or ConfigMaps, but instead as a single object that only exposes the knobs that make sense for the application.

# [HCO known as Hyper Converged Operator](https://github.com/kubevirt/hyperconverged-cluster-operator)  

## What it does?

The goal of the hyperconverged-cluster-operator (HCO) is to provide a single entrypoint for multiple operators - [kubevirt](https://blog.openshift.com/a-first-look-at-kubevirt/), [cdi](http://kubevirt.io/2018/CDI-DataVolumes.html), [networking](https://github.com/intel/multus-cni/blob/master/doc/quickstart.md), etc... - where users can deploy and configure them in a single object. This operator is sometimes referred to as a "meta operator" or an "operator for operators". Most importantly, this operator doesn't replace or interfere with OLM. It only creates operator CRs, which is the user's prerogative.

## How does it work?

In this blog post, I'd like to focus on the first method(i.e by deploying a HCO using a CustomResourceDefinition method which might seem like the most immediate benefit of this feature. Let's get started!

### Environment description
We can use HCO both on minikube and also on Openshift4. 

* **Minikube**

Minikube is a tool that makes it easy to run Kubernetes locally. Minikube runs a single-node Kubernetes cluster inside a VM on your laptop for users looking to try out Kubernetes or develop with it day-to-day.
For testing Hyper Converged Operator I have deployed a single-node K8's cluster with the name kubevirt-hco. This can be deployed using [minikube](https://kubernetes.io/docs/setup/minikube/#installation):

We’ll create a profile for KubeVirt so it gets its own settings without interfering what any configuration you might had already, let’s start by increasing the default memory to 4GiB:
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
### Using the HCO on minikube

Clone the HCO repo [here](https://github.com/kubevirt/hyperconverged-cluster-operator)

```
git clone https://github.com/kubevirt/hyperconverged-cluster-operator.git
```
This gives all the necessary `go` packages and `yaml` manifests for the next steps.
 
Lets create a NameSpace for the HCO deployment

```
kubectl create namespace kubevirt-hyperconverged
```
Now switch to the `kubevirt-hyperconverged` NameSpace

```
kubectl config set-context $(kubectl config current-context) --namespace=kubevirt-hyperconverged
```
Now launch all the CRD's

```
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

```shell
$ kubectl create -f deploy/converged
```

And after verifying all the above resources we can now finally deploy our HCO custom resource 

```shell
$ kubectl create -f deploy/converged/crds/hco.cr.yaml 
```
We can take a look at the YAML definition of the CustomResource of HCO:

```yaml
---
apiVersion: hco.kubevirt.io/v1alpha1
kind: HyperConverged
metadata:
  name: hyperconverged-cluster
spec:
  CDIImagePullPolicy: IfNotPresent
  KubeVirtImagePullPolicy: IfNotPresent
```

After succesfully executing the above commands,we should be now be having a `virt-controller` pod, HCO pod,and a `network-addon` pod functional and can be viewed as below

Lets see the deployed pods

```
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

We can see the CRD's in the which has a cluster-wide scope: 

```
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

```
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
#> **NOTE**: Here, Once we applied the Custom Resource the operator took care of deploying the actual KubeVirt pods (virt-api, virt-controller and virt-handler), CDI pods(cdi-upload-proxy, cdi-apiserver, cdi-deployment, cdi-operator) and Network add-on pods ( cluster-network-addons-operator)  . Again we’ll need to execute the command until everything is up&running (or use -w).

## Deploying HCO Openshift4 Cluster.

[Openshift](https://www.openshift.com/learn/what-is-openshift/)

Installation steps for OCP4 including video tutorial can be found [here](https://blog.openshift.com/installing-openshift-4-from-start-to-finish/) 

After, we have the running cluster which has 3 master and 3 workers, we can start our HCO integration.
```
$oc version
Client Version: version.Info{Major:"4", Minor:"1+", GitVersion:"v4.1.0", GitCommit:"2793c3316", GitTreeState:"", BuildDate:"2019-04-23T07:46:06Z", GoVersion:"", Compiler:"", Platform:""}
Server Version: version.Info{Major:"1", Minor:"12+", GitVersion:"v1.12.4+0ba401e", GitCommit:"0ba401e", GitTreeState:"clean", BuildDate:"2019-03-31T22:28:12Z", GoVersion:"go1.10.8", Compiler:"gc", Platform:"linux/amd64"}
```
Check the nodes 
```
$oc get nodes
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-135-62.us-east-2.compute.internal    Ready    master   23h   v1.12.4+509916ce1
ip-10-0-142-184.us-east-2.compute.internal   Ready    worker   22h   v1.12.4+509916ce1
ip-10-0-146-223.us-east-2.compute.internal   Ready    master   23h   v1.12.4+509916ce1
ip-10-0-150-253.us-east-2.compute.internal   Ready    worker   22h   v1.12.4+509916ce1
ip-10-0-167-105.us-east-2.compute.internal   Ready    worker   22h   v1.12.4+509916ce1
ip-10-0-174-7.us-east-2.compute.internal     Ready    master   23h   v1.12.4+509916ce1
```
After the HCO is up and running on the cluster, we should be able to see the info of CRD's

```
$oc get crds | grep kubevirt
cdis.cdi.kubevirt.io                                             2019-04-23T17:36:02Z
hyperconvergeds.hco.kubevirt.io                                  2019-04-23T17:35:37Z
kubevirts.kubevirt.io                                            2019-04-23T17:35:51Z
networkaddonsconfigs.networkaddonsoperator.network.kubevirt.io   2019-04-23T17:36:12Z
```
##Note: Just replace `kubectl` with `oc` to get HCO up and running on Openshift.

## Here is the yaml file for CDI, CNI and KubeVirt:

[CDI](https://github.com/kubevirt/kubevirt.github.io/blob/master/_posts/2018-10-10-CDI-DataVolumes.markdown): Container Data Importer(or CDI for short), is a data import service for Kubernetes designed with KubeVirt in mind. Thanks to CDI, we can now enjoy the addition of DataVolumes, which greatly improve the workflow of managing KubeVirt and its storage.

```yaml
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: cdis.cdi.kubevirt.io
spec:
  additionalPrinterColumns:
  - JSONPath: .metadata.creationTimestamp
    name: Age
    type: date
  - JSONPath: .status.phase
    name: Phase
    type: string
  group: cdi.kubevirt.io
  names:
    kind: CDI
    listKind: CDIList
    plural: cdis
    shortNames:
    - cdi
    - cdis
    singular: cdi
  scope: Cluster
  subresources:
    status: {}
  version: v1alpha1
  versions:
  - name: v1alpha1
    served: true
    storage: true

```

[CNI](https://github.com/intel/multus-cni/blob/master/doc/quickstart.md): In short CNI-multus enables the pods with an additional network interface through which it can communicate with the pods. We can summarize this as for ex: if pod has three interface: eth0, net0 and net1. eth0 connects kubernetes cluster network to connect with kubernetes server/services (e.g. kubernetes api-server, kubelets and so on). net0 and net1 are network attachment and connect to other networks with other CNI networks (e.g. vlan/vxlan/ptp).

```yaml
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: networkaddonsconfigs.networkaddonsoperator.network.kubevirt.io
spec:
  group: networkaddonsoperator.network.kubevirt.io
  names:
    kind: NetworkAddonsConfig
    listKind: NetworkAddonsConfigList
    plural: networkaddonsconfigs
    singular: networkaddonsconfig
  scope: Cluster
  subresources:
    status: {}
  version: v1alpha1
  versions:
  - name: v1alpha1
    served: true
    storage: true
```

[KubeVirt](http://kubevirt.io/quickstart_minikube/) : In short , KubeVirt technology addresses the needs of development teams that have adopted or want to adopt [Kubernetes](https://kubernetes.io/) but possess existing Virtual Machine-based workloads that cannot be easily containerized. More specifically, the technology provides a unified development platform where developers can build, modify, and deploy applications residing in both Application Containers as well as Virtual Machines in a common, shared environment. 

So, after HCO is up and running we need to test it by deploying a small instance of a VM.For doing so, we need to follow the steps:

```
$export KUBEVIRT_VERSION="v0.16.1"
```

Download the binary `virtcl` which helps in getting a quick access to the serial and graphical ports of a VM, and can handle start/stop operations. 

```
$curl -L -o virtctl \
    https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
```
Also, give the executable permission to the virtctl 
```
$chmod +x virtctl
```
# Deploy a VirtualMachine 

```
$kubectl apply -f https://raw.githubusercontent.com/kubevirt/kubevirt.github.io/master/labs/manifests/vm.yaml
```

We can check the YAML definition:
```
$kubectl get vms
$kubectl get vms -o yaml testvm
```

#**Note**: The field **`running:`** is set to **`false`**, that means we only have defined the object but we now should instantiate it.

```
$./virtctl start testvm
```

Use **`virtctl`** to query the VM instance

```
$kubectl get vmis
$kubectl get vmis -o yaml testvm
```
#**Note**: The 'i' in **vmi** , as it stands for VirtualMachineInstance. Now, pay attention to the phase field, its value will be transitioning from one state to the next, indicating VMI progress to finish being set to Running.


Now use **virtctl** command to connect to the VMI consoles interfaces:
```
$./virtctl console testvm
$./virtctl vnc testvm
```
Remember that for exiting from the console to hit Ctrl+] (Control plus closing square bracket).

#**Note**: VNC requires remote-viewer from the virt-viewer package installed on the host.

Now its time for a Clean Up:

Let’s stop the VM instance:
```
$./virtctl stop testvm
```

Delete the VM:
```
$kubectl delete vm testvm
```

Delete the minikube instance:
```
$minikube delete -p kubevirt-hco
```

#**Conclusion**-What to expect next ?

HCO achieved its goal which was to provide a single entrypoint for multiple operators - kubevirt, cdi, networking, etc.where users can deploy and configure them in a single object as seen above.

Now, we can also launch the HCO through OLM, 

#**Note**: 
Until we publish (and consume) the HCO and component operators through Marketplace|[operatorhub.io](https://operatorhub.io/), this is a means to demonstrate the HCO workflow without OLM

Once we publish operators through Marketplace|operatorhub.io, it will be available [here](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md#installing-olm)



