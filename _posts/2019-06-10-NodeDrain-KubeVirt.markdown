---
layout: post
author: DirectedSoul
description: Evicting VM's using Node Drain Functionality
navbar_active: Blogs
pub-date: May 30
pub-year: 2019
category: news
---

# Node Drain Functionality:

**Motivation and Use case**

As we are all aware in k8s cluster control plane(scheduler) is responsible for deploying worloads(pods,deployments,replicasets) on the worker nodes depending on the resource availibility. What do we do with the workloads if the need arises for maintaining this node?. Well there is a good news, node drain feature and node maintenance operator(NMO) both come to our rescue in this situation. 
This Blog particularly discusses about evicting the [VMI](https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/intro.html)(virtual machine images) and other resources from the node using node drain feature and NMO.

**Note:**

- For this Blog, I have used [Openshift4](https://cloud.redhat.com/openshift/install) with 3 Masters and 3 Worker nodes.

- [HyperconvergedClusterOperator](https://github.com/kubevirt/hyperconverged-cluster-operator): The goal of the hyperconverged-cluster-operator (HCO) is to provide a single entrypoint for multiple operators - kubevirt, cdi, networking, ect... - where users can deploy and configure them in a single object. This operator is sometimes referred to as a "meta operator" or an "operator for operators". Most importantly, this operator doesn't replace or interfere with OLM. It only creates operator CRs, which is the user's prerogative.  

- [KubeVirt](https://github.com/kubevirt/kubevirt): KubeVirt is a virtual machine management add-on for Kubernetes. The aim is to provide a common ground for virtualization solutions on top of Kubernetes.

After we install Openshift 4 cluster:

~~~
$oc get nodes
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-140-114.us-east-2.compute.internal   Ready    master   15m   v1.13.4+27816e1b1
ip-10-0-140-153.us-east-2.compute.internal   Ready    worker   15m   v1.13.4+27816e1b1
ip-10-0-152-175.us-east-2.compute.internal   Ready    worker   15m   v1.13.4+27816e1b1
ip-10-0-156-213.us-east-2.compute.internal   Ready    master   15m   v1.13.4+27816e1b1
ip-10-0-163-116.us-east-2.compute.internal   Ready    master   15m   v1.13.4+27816e1b1
ip-10-0-164-160.us-east-2.compute.internal   Ready    worker   15m   v1.13.4+27816e1b1
~~~
To test the node eviction, there are mainly two methods. 


- Method1: Use kubectl node drain command: 

Before sending a node into maintenance state its very much necessary to evict the resources on it, VMI's, pods, deployments etc. One of the easiest option for us is to stick to the kubernetes `node-drain` or **oc adm drain** command. For this, select the node from the cluster from which you want the VMIs to be evicted

```
oc get nodes
```
Here `ip-10-0-140-153.us-east-2.compute.internal`, then issue the following command.

```
oc adm drain <node-name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher 
```
or 

```
kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher
```

- `--delete-local-data` is used to remove any VMI's that use emptyDir volumes, however the data in those volumes are ephemeral which means it is safe to delete after termination.

- `--ignore-daemonsets=true` is a must needed flag because when VMI is deployed a daemon set named `virt-handler` will be running on each node. DaemonSets are not allowed to be evicted using kubectl drain. By default, if this command encounters a DaemonSet on the target node, the command will fail. This flag tells the command it is safe to proceed with the eviction and to just ignore DaemonSets.

- `--pod-selector=kubevirt.io=virt-launcher` flag tells the command to evict the pods that are managed by kubevirt

If you want to evict all pods from the node from the above commmand just use:

```
kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force
```
we have seen how to make the node unschedulable, now lets see how to re-enable the node.

**Re-enabling a Node after Eviction**
The kubectl drain will result in the target node being marked as unschedulable. This means the node will not be eligible for running new VirtualMachineInstances or Pods.
If it is decided that the target node should become schedulable again, the following command must be run.
```
kubectl uncordon <node name>
```
or in the case of OpenShift
```
oc adm uncordon <node name>
```

- **Method2:** 
We need to deploy the HyperConvergedClusterOperator, the gist for the same can be found [here](https://gist.github.com/rthallisey/ed3417bc7f14f264030d26fee4032092)

~~~
$ curl https://gist.github.com/rthallisey/ed3417bc7f14f264030d26fee4032092
.
.
.
+ echo 'Launching CNV...'
Launching CNV...
+ cat
+ oc create -f -
hyperconverged.hco.kubevirt.io/hyperconverged-cluster created
~~~

Observe the resources that get created after the HCO is installed
~~~
$oc get pods -n kubevirt-hyperconverged
NAME                                               READY   STATUS    RESTARTS   AGE
cdi-apiserver-769fcc7bdf-xgpt8                     1/1     Running   0          12m
cdi-deployment-8b64c5585-gq46b                     1/1     Running   0          12m
cdi-operator-77b8847b96-kx8rx                      1/1     Running   0          13m
cdi-uploadproxy-8dcdcbff-47lng                     1/1     Running   0          12m
cluster-network-addons-operator-584dff99b8-2c96w   1/1     Running   0          13m
hco-operator-59b559bd44-vpznq                      1/1     Running   0          13m
kubevirt-ssp-operator-67b78446f7-b9klr             1/1     Running   0          13m
kubevirt-web-ui-operator-9df6b67d9-f5l4l           1/1     Running   0          13m
**node-maintenance-operator-6b464dc85-zd6nt**    **1/1** **Running** **0**    **13m**
virt-api-7655b9696f-g48p8                          1/1     Running   1          12m
virt-api-7655b9696f-zfsw9                          1/1     Running   0          12m
virt-controller-7c4584f4bc-6lmxq                   1/1     Running   0          11m
virt-controller-7c4584f4bc-6m62t                   1/1     Running   0          11m
virt-handler-cfm5d                                 1/1     Running   0          11m
virt-handler-ff6c8                                 1/1     Running   0          11m
virt-handler-mcl7r                                 1/1     Running   1          11m
virt-operator-87d7c98b-fvvzt                       1/1     Running   0          13m
virt-operator-87d7c98b-xzc42                       1/1     Running   0          13m
virt-template-validator-76cbbd6f68-5fbzx           1/1     Running   0          12m
~~~

As seen from above HCO deploys the `node-maintenance-operator`.

Next,Let's install a kubevirt CR to start using VM workloads on worker nodes. Please feel free to follow the steps [here](https://kubevirt.io//quickstart_minikube/#deploy-kubevirt) and deploy a VMI as explained.Please feel free to check the video that explains the [same](https://www.youtube.com/watch?v=LLNjyeB-3fI)
~~~
$oc get vms
NAME     AGE     RUNNING   VOLUME
testvm   2m13s   true
~~~

Deploy a node-maintenance-operator CR: As seen from above NMO is deployed from HCO, The purpose of this operator is to watch the node maintenance CustomResource(CR) called `NodeMaintenance` which mainly contains the node that needs a maintenance and the reason for the same. The below actions are performed 

1. If a `NodeMaintenance` CR is created: Marks the node as unschedulable, cordons it and evicts all the pods from that node

2. If a `NodeMaintenance` CR is deleted: Marks the node as schedulable, uncordons it, removes pod from maintenance.

To install the NMO please follow the instructions from [NMO](https://github.com/kubevirt/node-maintenance-operator)
Either use HCO to create NMO Operator or deploy NMO operator as shown below 
After you follow the instructions:
1. Create a CRD
~~~
oc create -f deploy/crds/nodemaintenance_crd.yaml
customresourcedefinition.apiextensions.k8s.io/nodemaintenances.kubevirt.io created
~~~
2. Create the NS
~~~
oc create -f deploy/namespace.yaml 
namespace/node-maintenance-operator created
~~~
3. Create a Service Account:
~~~
oc create -f deploy/service_account.yaml
serviceaccount/node-maintenance-operator created
~~~
4. Create a ROLE
~~~
oc create -f deploy/role.yaml
clusterrole.rbac.authorization.k8s.io/node-maintenance-operator created
~~~
4. Create a ROLE Binding
~~~
oc create -f deploy/role_binding.yaml
clusterrolebinding.rbac.authorization.k8s.io/node-maintenance-operator created
~~~
5. Then finally make sure to add the image version of the NMO operator in the deploy/operator.yml 
~~~
image: quay.io/kubevirt/node-maintenance-operator:v0.3.0
~~~
and then deploy the NMO Operator as shown
~~~
oc create -f deploy/operator.yaml
deployment.apps/node-maintenance-operator created
~~~
We can verify the deployment for the NMO Operator as below
~~~
oc get deployment -n node-maintenance-operator
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
node-maintenance-operator   1/1     1            1           4m23s
~~~

Now that the NMO operator is created, we can create the NMO CR which sends the node into maintenance mode ( this CR has the info about the node->from which the pods needs to be evicted and the reason for the maintenance) 
~~~
cat deploy/crds/nodemaintenance_cr.yaml

apiVersion: kubevirt.io/v1alpha1
kind: NodeMaintenance
metadata:
  name: nodemaintenance-xyz
spec:
  nodeName: <Node-Name>
  reason: "Test node maintenance"
~~~
For testing purpose, we can deploy a nginx pod as shown
~~~
kubectl run lab-pod --image=nginx --port=80 --labels="app=web,env=dev" --generator=run-pod/v1
pod/lab-pod created
~~~
~~~
oc get pods -o wide
NAME      READY   STATUS    RESTARTS   AGE   IP            NODE                                         NOMINATED NODE   READINESS GATES
lab-pod   1/1     Running   0          16s   10.128.2.11   ip-10-0-165-139.us-east-2.compute.internal   <none>           <none>
~~~
Note down the node name and edit the `nodemaintenance_cr.yaml` file and then issue the CR manifest which sends the node into maintenance.


**Conclusion:**

VirtualMachine Evictions
The eviction of any VirtualMachineInstance that is owned by a VirtualMachine set to running=true will result in the VirtualMachineInstance being re-scheduled to another node.

The VirtualMachineInstance in this case will be forced to power down and restart on another node. In the future once KubeVirt introduces live migration support, the VM will be able to seamlessly migrate to another node during eviction.





