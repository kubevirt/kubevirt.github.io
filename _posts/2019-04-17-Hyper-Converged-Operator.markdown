---
layout: post
author: DirectedSoul
description: Hyper Converged Operator on OCP4 and K8s(HCO) 
navbar_active: Blogs
pub-date: May 08
pub-year: 2019
category: news
---

# [HCO known as Hyper Converged Operator](https://github.com/kubevirt/hyperconverged-cluster-operator)  

**Prerequisites:** 
 
This Blog assumes that the reader is aware of the concept of Operators and how it works in K8's environment. Before proceeding further, feel free to take a look at this concept using [CoreOS BlogPost](https://coreos.com/blog/introducing-operators.html)

## What it does?

The goal of the hyperconverged-cluster-operator (HCO) is to provide a single entrypoint for multiple operators - [kubevirt](https://blog.openshift.com/a-first-look-at-kubevirt/), [cdi](http://kubevirt.io/2018/CDI-DataVolumes.html), [networking](https://github.com/intel/multus-cni/blob/master/doc/quickstart.md), etc... - where users can deploy and configure them in a single object. This operator is sometimes referred to as a "meta operator" or an "operator for operators". Most importantly, this operator doesn't replace or interfere with OLM. It only creates operator CRs, which is the user's prerogative.

## How does it work?

In this blog post, I'd like to focus on the first method(i.e by deploying a HCO using a CustomResourceDefinition method)which might seem like the most immediate benefit of this feature. Let's get started!

### Environment description
We can use HCO both on minikube and also on Openshift4. 

Minikube is a tool that makes it easy to run Kubernetes locally. Minikube runs a single-node Kubernetes cluster inside a VM on your laptop for users looking to try out Kubernetes or develop with it day-to-day.
For testing Hyper Converged Operator I have deployed a single-node K8's cluster with the name kubevirt-hco. This can be deployed using [minikube](https://kubernetes.io/docs/setup/minikube/#installation):

We'll create a profile for KubeVirt allowing us to define specific settings and to ensure the settings don't interfere with any configuration you might had already, let’s start by increasing the default memory to 4GiB:

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

```
$kubectl get crds 
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

Now, lets take a look at CRD's which has a cluster-wide scope as seen below: 

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
#**NOTE**: Here, Once we applied the Custom Resource the operator took care of deploying the actual KubeVirt pods (virt-api, virt-controller and virt-handler), CDI pods(cdi-upload-proxy, cdi-apiserver, cdi-deployment, cdi-operator) and Network add-on pods ( cluster-network-addons-operator).We will need to wait until all of the resources are up and running. This can be done using the command above or by using the command above with the -w flag.

## Deploying HCO Openshift4 Cluster.

[Openshift](https://www.openshift.com/learn/what-is-openshift/)

Installation steps for Openshift4 including video tutorial can be found [here](https://blog.openshift.com/installing-openshift-4-from-start-to-finish/) 

Upon successful installation of OpenShift, we will have a cluster consistening of 3 masters and 3 workers which can be used for HCO integration

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
#Note: In Openshift we can use both `kubectl` and  `oc` interchangeably to interact with the cluster objects once HCO is up and running.

## You can read more about CDI, CNI and KubeVirt:

- [CDI](https://github.com/kubevirt/kubevirt.github.io/blob/master/_posts/2018-10-10-CDI-DataVolumes.markdown) 

- [CNI](https://github.com/intel/multus-cni/blob/master/doc/quickstart.md)

- [KubeVirt](http://kubevirt.io/quickstart_minikube/) 

# [HCO using the OLM method](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/architecture.md) 

The complete architecture of OLM and its components that connect together can be understood using the link [OLM_architecture](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/architecture.md) 

Replace <docker_org> with your Docker organization as official operator-registry images for HCO will not be provided. 

Next, build and publish the converged HCO operator-registry image.

```
cd deploy/converged
export HCO_DOCKER_ORG=<docker_org>
docker build --no-cache -t docker.io/$HCO_DOCKER_ORG/hco-registry:example -f Dockerfile .
docker push docker.io/$HCO_DOCKER_ORG/hco-registry:example
```
As an example deployment, Let's take the value of operator-registry image as 

```
docker.io/rthallisey/hyperconverged-cluster-operator:latest
```

Now, Let's create the `kubevirt-hyperconverged` NS as below

```
oc create ns kubevirt-hyperconverged
```

Create the OperatorGroup

```
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: hco-operatorgroup
  namespace: kubevirt-hyperconverged
EOF
```

Create a Catalog Source backed by a grpc registry

```
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: hco-catalogsource
  namespace: openshift-operator-lifecycle-manager
  imagePullPolicy: Always
spec:
  sourceType: grpc
  image: docker.io/rthallisey/hco-registry:v0.1-8
  displayName: KubeVirt HyperConverged
  publisher: Red Hat
EOF
```
Please wait until the `hco-catalogsource` pod comes up

Next is to create a subscription:

```
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: hco-subscription
  namespace: kubevirt-hyperconverged
spec:
  channel: alpha
  name: kubevirt-hyperconverged
  source: hco-catalogsource
  sourceNamespace: openshift-operator-lifecycle-manager
EOF

sleep 60
```
Wait until the `virt-operator`, `cdi-operator` and `cluster-network-addons-operator` comes up. 

After they are up, its now time to launch the HCO-Custom Resource itself:

```
cat <<EOF | oc create -f -
apiVersion: hco.kubevirt.io/v1alpha1
kind: HyperConverged
metadata:
  name: hyperconverged-cluster
  namespace: kubevirt-hyperconverged
EOF
```

Once the HCO Operator is deployed in the `kubevirt-hyperconverged` NS, we can see all the pods are up and running:

```
🎩oc get pods

NAME                                               READY   STATUS    RESTARTS   AGE
cdi-apiserver-769fcc7bdf-97q8r                     1/1     Running   0          83m
cdi-deployment-8b64c5585-5txmd                     1/1     Running   0          83m
cdi-operator-77b8847b96-2zxtz                      1/1     Running   0          84m
cdi-uploadproxy-8dcdcbff-v7stq                     1/1     Running   0          83m
cluster-network-addons-operator-584dff99b8-cqd7g   1/1     Running   0          84m
hco-operator-59b559bd44-5dg6j                      1/1     Running   0          84m
kubevirt-ssp-operator-67b78446f7-9phxj             1/1     Running   0          84m
kubevirt-web-ui-operator-9df6b67d9-djjcs           1/1     Running   0          84m
node-maintenance-operator-6b464dc85-6ml2z          1/1     Running   0          84m
virt-api-85b47b44db-28x96                          1/1     Running   0          83m
virt-api-85b47b44db-n4v4r                          1/1     Running   0          83m
virt-controller-59fbcc9f9b-44sgx                   1/1     Running   0          82m
virt-controller-59fbcc9f9b-p9jpf                   1/1     Running   0          82m
virt-handler-bl657                                 1/1     Running   1          82m
virt-handler-lszwp                                 1/1     Running   0          82m
virt-handler-sfgtj                                 1/1     Running   0          82m
virt-operator-87d7c98b-5pmlw                       1/1     Running   0          84m
virt-operator-87d7c98b-rngqq                       1/1     Running   0          84m
```
We can see how OLM operator manages the HCO pods from the `openshift-operator-lifecycle-manager` NS:

```
oc get pods -n openshift-operator-lifecycle-manager
NAME                                READY   STATUS    RESTARTS   AGE
catalog-operator-56cbfb5965-8fm7r   1/1     Running   0          104m
hco-catalogsource-tmltb             1/1     Running   0          85m
olm-operator-77d8f864d-8hsf5        1/1     Running   0          104m
olm-operators-8qqgn                 1/1     Running   0          102m
packageserver-85f4964547-sjswg      1/1     Running   0          101m
packageserver-85f4964547-t6j5q      1/1     Running   0          101m
```
The above method demonstrates the integration of HCO operator in Openshift4.

So, after HCO is up and running we need to test it by deploying a small instance of a VM.To deploy an instance follow the instructions here [minikube_quickstart](https://kubevirt.io//quickstart_minikube/#install-virtctl):

#**Note**: You can delete the minikube instance after you are done testing the VM.

#Cleaning up the minikube instance:

```
$minikube delete -p kubevirt-hco
```

## Conclusion

What to expect next ?

HCO achieved its goal which was to provide a single entrypoint for multiple operators - kubevirt, cdi, networking, etc.where users can deploy and configure them in a single object as seen above.

Now, we can also launch the HCO through OLM, 

**Note**: 
Until we publish (and consume) the HCO and component operators through Marketplace|[operatorhub.io](https://operatorhub.io/), this is a means to demonstrate the HCO workflow without OLM

Once we publish operators through Marketplace|operatorhub.io, it will be available [here](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md#installing-olm)



