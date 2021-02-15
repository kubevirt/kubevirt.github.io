---
layout: post
author: DirectedSoul
description: Evicting VM's using Node Drain Functionality
title: Node Drain in KubeVirt
navbar_active: Blogs
pub-date: Jul 30
pub-year: 2019
category: news
tags: [node drain, eviction, nmo]
---

## Introduction

In a Kubernetes (k8s) cluster, the control plane(scheduler) is responsible for deploying workloads(`pods`, `deployments`, `replicasets`) on the worker nodes depending on the resource availability. What do we do with the workloads if the need arises for maintaining this node? Well, there is good news, `node-drain` feature and node maintenance operator(NMO) both come to our rescue in this situation.

This post discusses evicting the [VMI](https://kubevirt.io/user-guide/virtual_machines/virtual_machine_instances/#virtual-machines-instances)(virtual machine instance) and other resources from the node using node drain feature and NMO.

> note "Note"
> The environment used for writing this post is based on [OpenShift 4](https://cloud.redhat.com/openshift/install/aws/installer-provisioned) with 3 Masters and 3 Worker nodes.

- [HyperconvergedClusterOperator]({% post_url 2019-04-17-Hyper-Converged-Operator %}): The goal of the hyper-converged-cluster-operator (HCO) is to provide a single entry point for multiple operators (kubevirt, cdi, networking, etc) where users can deploy and configure them in a single object. This operator is sometimes referred to as a "meta operator" or an "operator for operators". Most importantly, this operator doesn't replace or interfere with OLM which is an open source toolkit to manage Kubernetes native applications, called Operators, in an effective, automated, and scalable way. Check for [more information about OLM](https://coreos.com/blog/introducing-operator-framework). It only creates operator CRs, which is the user's prerogative.

In our cluster (3 master and 3 nodes) we'll be able to see something similar to:

```sh
$oc get nodes
ip-10-0-132-147.us-east-2.compute.internal   Ready  worker   14m   v1.13.4+27816e1b1
ip-10-0-142-95.us-east-2.compute.internal    Ready  master   15m   v1.13.4+27816e1b1
ip-10-0-144-125.us-east-2.compute.internal   Ready  worker   14m   v1.13.4+27816e1b1
ip-10-0-150-125.us-east-2.compute.internal   Ready  master   14m   v1.13.4+27816e1b1
ip-10-0-161-166.us-east-2.compute.internal   Ready  master   15m   v1.13.4+27816e1b1
ip-10-0-173-203.us-east-2.compute.internal   Ready  worker   15m   v1.13.4+27816e1b1
```

To test the node eviction, there are two methods.

## Method 1: Use kubectl node drain command

Before sending a node into maintenance state it is very much necessary to evict the resources on it, VMI's, pods, deployments etc. One of the easiest option for us is to stick to the oc adm drain command. For this, select the node from the cluster from which you want the VMIs to be evicted

```sh
oc get nodes
```

Here `ip-10-0-173-203.us-east-2.compute.internal`, then issue the following command.

```sh
oc adm drain <node-name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher
```

- `--delete-local-data` is used to remove any VMI's that use `emptyDir` volumes, however the data in those volumes are ephemeral which means it is safe to delete after termination.

- `--ignore-daemonsets=true` is a must needed flag because when VMI is deployed a daemon set named `virt-handler` will be running on each node. DaemonSets are not allowed to be evicted using kubectl drain. By default, if this command encounters a DaemonSet on the target node, the command will fail. This flag tells the command it is safe to proceed with the eviction and to just ignore DaemonSets.

- `--pod-selector=kubevirt.io=virt-launcher` flag tells the command to evict the pods that are managed by kubevirt

### Evict a node

If you want to evict all pods from the node just use:

```sh
oc adm drain <node name> --delete-local-data --ignore-daemonsets=true --force
```

### How to evacuate VMIs via Live Migration from a Node

If the `LiveMigration` feature gate is enabled, it is possible to specify an evictionStrategy on VMIs which will react with live-migrations on specific taints on nodes. The following snippet on a VMI ensures that the VMI is migrated if the `kubevirt.io/drain:NoSchedule` taint is added to a node:

```yaml
spec:
  evictionStrategy: LiveMigrate
```

Once the VMI is created, taint the node with

```sh
kubectl taint nodes foo kubevirt.io/drain=draining:NoSchedule
```

This command will then trigger a migration.

Behind the scenes a **PodDisruptionBudget** is created for each VMI which has an evictionStrategy defined. This ensures that evictions are be blocked on these VMIs and that we can guarantee that a VMI will be migrated instead of shut off.

### Re-enabling a Node after Eviction

We have seen how to make the node unschedulable, now lets see how to re-enable the node.

The `oc adm drain` will result in the target node being marked as unschedulable. This means the node will not be eligible for running new VirtualMachineInstances or Pods.

If target node should become schedulable again, the following command must be run:

```sh
oc adm uncordon <node name>
```

## Method 2: Use Node Maintenance Operator (NMO)

NMO is part of HyperConvergedClusterOperator, so we need to deploy it.

Either check:

- the [gist for deploying HCO](https://gist.github.com/rthallisey/ed3417bc7f14f264030d26fee4032092)
- the [blog post on HCO]({% post_url 2019-04-17-Hyper-Converged-Operator %})

Here will continue using the gist for demonstration purposes.

Observe the resources that get created after the HCO is installed

```
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
node-maintenance-operator-6b464dc85-zd6nt          1/1     Running   0          13m
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
```

As seen from above HCO deploys the `node-maintenance-operator`.

Next, let's install a kubevirt CR to start using VM workloads on worker nodes. Please feel free to follow the steps [here]({% link pages/quickstart_minikube.md  %}#deploy-kubevirt) and deploy a VMI as explained. Please feel free to check the video that explains the [same](https://www.youtube.com/watch?v=LLNjyeB-3fI)

```sh
$oc get vms
NAME     AGE     RUNNING   VOLUME
testvm   2m13s   true
```

Deploy a node-maintenance-operator CR: As seen from above NMO is deployed from HCO, the purpose of this operator is to watch the node maintenance CustomResource(CR) called `NodeMaintenance` which mainly contains the node that needs a maintenance and the reason for it. The below actions are performed

- If a `NodeMaintenance` CR is created: Marks the node as `unschedulable`, cordons it and evicts all the pods from that node
- If a `NodeMaintenance` CR is deleted: Marks the node as `schedulable`, uncordons it, removes pod from maintenance.

To install the NMO, please follow upsream instructions at [NMO](https://github.com/kubevirt/node-maintenance-operator)

Either use HCO to create NMO Operator or deploy NMO operator as shown below

After you follow the instructions:

1. Create a CRD
   ```sh
   oc create -f deploy/crds/nodemaintenance_crd.yaml
   customresourcedefinition.apiextensions.k8s.io/nodemaintenances.kubevirt.io created
   ```
2. Create the NS
   ```sh
   oc create -f deploy/namespace.yaml
   namespace/node-maintenance-operator created
   ```
3. Create a Service Account:
   ```sh
   oc create -f deploy/service_account.yaml
   serviceaccount/node-maintenance-operator created
   ```
4. Create a ROLE
   ```sh
   oc create -f deploy/role.yaml
   clusterrole.rbac.authorization.k8s.io/node-maintenance-operator created
   ```
5. Create a ROLE Binding
   ```sh
   oc create -f deploy/role_binding.yaml
   clusterrolebinding.rbac.authorization.k8s.io/node-maintenance-operator created
   ```
6. Then finally make sure to add the image version of the NMO operator in the deploy/operator.yml
   ```sh
   image: quay.io/kubevirt/node-maintenance-operator:v0.3.0
   ```
7. and then deploy the NMO Operator as shown
   ```sh
   oc create -f deploy/operator.yaml
   deployment.apps/node-maintenance-operator created
   ```

Finally, We can verify the deployment for the NMO Operator as below

```sh
oc get deployment -n node-maintenance-operator
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
node-maintenance-operator   1/1     1            1           4m23s
```

Now that the NMO operator is created, we can create the NMO CR which puts the node into maintenance mode (this CR has the info about the node->from which the pods needs to be evicted and the reason for the maintenance)

```yaml
cat deploy/crds/nodemaintenance_cr.yaml

apiVersion: kubevirt.io/v1alpha1
kind: NodeMaintenance
metadata:
  name: nodemaintenance-xyz
spec:
  nodeName: <Node-Name>
  reason: "Test node maintenance"
```

For testing purpose, we can deploy a sample VM instance as shown:

```sh
kubectl apply -f https://raw.githubusercontent.com/kubevirt/kubevirt.github.io/master/labs/manifests/vm.yaml
```

Now start the VM `testvm`

```sh
./virtctl start testvm
```

We can see that it's up and running

```sh
kubectl get vmis
NAME     AGE   PHASE     IP            NODENAME
testvm   92s   Running   10.131.0.17   ip-10-0-173-203.us-east-2.compute.internal
```

Also, we can see the status:

```yaml
kubectl get vmis -o yaml testvm
.
.
.
  interfaces:
  - ipAddress: 10.131.0.17
    mac: 0a:58:0a:83:00:11
    name: default
  migrationMethod: BlockMigration
  nodeName: ip-10-0-173-203.us-east-2.compute.internal    #NoteDown the nodeName
  phase: Running
```

Note down the node name and edit the `nodemaintenance_cr.yaml` file and then issue the CR manifest which sends the node into maintenance.

Now to evict the pods from the node `ip-10-0-173-203.us-east-2.compute.internal`, edit the `node-maintenance_cr.yaml` as shown:

```yaml
cat deploy/crds/nodemaintenance_cr.yaml

apiVersion: kubevirt.io/v1alpha1
kind: NodeMaintenance
metadata:
  name: nodemaintenance-xyz
spec:
  nodeName: ip-10-0-173-203.us-east-2.compute.internal
  reason: "Test node maintenance"
```

As soon as you apply the above CR, the current VM gets deployed in the other node,

```sh
oc apply -f deploy/crds/nodemaintenance_cr.yaml
nodemaintenance.kubevirt.io/nodemaintenance-xyz created
```

Which immediately evicts the VMI

```sh
kubectl get vmis
NAME     AGE   PHASE        IP    NODENAME
testvm   33s   Scheduling

kubectl get vmis
NAME     AGE    PHASE     IP            NODENAME
testvm   104s   Running   10.128.2.20   ip-10-0-132-147.us-east-2.compute.internal
```

```
ip-10-0-173-203.us-east-2.compute.internal   Ready,SchedulingDisabled   worker
```

When all of this happens, we can view the changes that are taking place with:

```json
oc logs pods/node-maintenance-operator-645f757d5-89d6r -n node-maintenance-operator
.
.
.
{"level":"info","ts":1559681430.650298,"logger":"controller_nodemaintenance","msg":"Applying Maintenance mode on Node: ip-10-0-173-203.us-east-2.compute.internal with Reason: Test node maintenance","Request.Namespace":"","Request.Name":"nodemaintenance-xyz"}
{"level":"info","ts":1559681430.7509086,"logger":"controller_nodemaintenance","msg":"Taints: [{\"key\":\"node.kubernetes.io/unschedulable\",\"effect\":\"NoSchedule\"},{\"key\":\"kubevirt.io/drain\",\"effect\":\"NoSchedule\"}] will be added to node ip-10-0-173-203.us-east-2.compute.internal"}
{"level":"info","ts":1559681430.7509348,"logger":"controller_nodemaintenance","msg":"Applying kubevirt.io/drain taint add on Node: ip-10-0-173-203.us-east-2.compute.internal"}
{"level":"info","ts":1559681430.7509415,"logger":"controller_nodemaintenance","msg":"Patchi{"level":"info","ts":1559681430.9903986,"logger":"controller_nodemaintenance","msg":"evicting pod \"virt-controller-b94d69456-b9dkw\"\n"}
{"level":"info","ts":1559681430.99049,"logger":"controller_nodemaintenance","msg":"evicting pod \"community-operators-5cb68db58-4m66j\"\n"}
{"level":"info","ts":1559681430.9905066,"logger":"controller_nodemaintenance","msg":"evicting pod \"alertmanager-main-1\"\n"}
{"level":"info","ts":1559681430.9905581,"logger":"controller_nodemaintenance","msg":"evicting pod \"virt-launcher-testvm-q5t7l\"\n"}
{"level":"info","ts":1559681430.9905746,"logger":"controller_nodemaintenance","msg":"evicting pod \"redhat-operators-6b6f6bd788-zx8nm\"\n"}
{"level":"info","ts":1559681430.990588,"logger":"controller_nodemaintenance","msg":"evicting pod \"image-registry-586d547bb5-t9lwr\"\n"}
{"level":"info","ts":1559681430.9906075,"logger":"controller_nodemaintenance","msg":"evicting pod \"kube-state-metrics-5bbd4c45d5-sbnbg\"\n"}
{"level":"info","ts":1559681430.9906383,"logger":"controller_nodemaintenance","msg":"evicting pod \"certified-operators-9f9f6fd5c-9ltn8\"\n"}
{"level":"info","ts":1559681430.9908028,"logger":"controller_nodemaintenance","msg":"evicting pod \"virt-api-59d7c4b595-dkpvs\"\n"}
{"level":"info","ts":1559681430.9906204,"logger":"controller_nodemaintenance","msg":"evicting pod \"router-default-6b57bcc884-frd57\"\n"}
{"level":"info","ts":1559681430.9908257,"logger":"controller_nodemaintenance","msg":"evict
```

Clearly we can see that the previous node went into `SchedulingDisabled` state and the VMI was evicted and placed into other node in the cluster. This demonstrates the node eviction using NMO.

## VirtualMachine Evictions notes

The eviction of any VirtualMachineInstance that is owned by a VirtualMachine set to running=true will result in the VirtualMachineInstance being re-scheduled to another node.

The VirtualMachineInstance in this case will be forced to power down and restart on another node. In the future once KubeVirt introduces live migration support, the VM will be able to seamlessly migrate to another node during eviction.

## Wrap-up

The NMO achieved its aim of evicting the VMI's successfully from the node, hence we can now safely repair/update the node and make it available for running the workloads again once the maintenance is over.
