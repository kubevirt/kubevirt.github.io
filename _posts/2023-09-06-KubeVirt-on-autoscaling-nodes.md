---
layout: post
author: Mark Maglana, Jonathan Kinred, Paul Myjavec
title: Running KubeVirt with Cluster Autoscaler
description: This post explains how to set up KubeVirt with Cluster Autoscaler on EKS
navbar_active: Blogs
pub-date: September 6
pub-year: 2023
category: news
tags:
  [
    "Kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "Cluster Autoscaler",
    "AWS",
    "EKS",
  ]
comments: true
---

## Introduction

For this article, we'll learn about the process of setting up
[KubeVirt](https://kubevirt.io/) with [Cluster
Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
on EKS. In addition, we'll be using bare metal nodes to host KubeVirt VMs.

## Required Base Knowledge

This article will talk about how to make various software systems work together
but introducing each one in detail is outside of its scope. Thus, you must already:

1. Know how to administer a Kubernetes cluster;
2. Be familiar with AWS, specifically IAM and EKS; and
3. Have some experience with KubeVirt.

## Companion Code

All the code used in this article may also be found at
[github.com/relaxdiego/kubevirt-cas-baremetal](https://github.com/relaxdiego/kubevirt-cas-baremetal).

## Set Up the Cluster

### Shared environment variables

First let's set some environment variables:

```bash
# The name of the EKS cluster we're going to create
export RD_CLUSTER_NAME=my-cluster

# The region where we will create the cluster
export RD_REGION=us-west-2

# Kubernetes version to use
export RD_K8S_VERSION=1.27

# The name of the keypair that we're going to inject into the nodes. You
# must create this ahead of time in the correct region.
export RD_EC2_KEYPAIR_NAME=eks-my-cluster
```

### Prepare the cluster.yaml file

Using [eksctl](https://eksctl.io/), prepare an EKS cluster config:

```bash
eksctl create cluster \
    --dry-run \
    --name=${RD_CLUSTER_NAME} \
    --nodegroup-name ng-infra \
    --node-type m5.xlarge \
    --nodes 2 \
    --nodes-min 2 \
    --nodes-max 2 \
    --node-labels workload=infra \
    --region=${RD_REGION} \
    --ssh-access \
    --ssh-public-key ${RD_EC2_KEYPAIR_NAME} \
    --version ${RD_K8S_VERSION} \
    --vpc-nat-mode HighlyAvailable \
    --with-oidc \
> cluster.yaml
```

`--dry-run` means the command will not actually create the cluster but will
instead output a config to stdout which we then write to `cluster.yaml`.

Open the file and look at what it has produced.

> For more info on the schema used by `cluster.yaml`, see the [Config file
> schema](https://eksctl.io/usage/schema/) page from eksctl.io

This cluster will start out with a node group that we will use to host our
"infra" services. This is why we are using the cheaper `m5.xlarge` rather than
a baremetal instance type. However, we also need to ensure that none of our VMs
will ever be scheduled in these nodes. Thus we need to taint them. In the
generated `cluster.yaml` file, append the following taint to the only node
group in the `managedNodeGroups` list:

```yaml
managedNodeGroups:
- amiFamily: AmazonLinux2
  ...
  taints:
    - key: CriticalAddonsOnly
      effect: NoSchedule
```

### Create the cluster

We can now create the cluster:

```bash
eksctl create cluster --config-file cluster.yaml
```

Example output:

```
2023-08-20 07:59:14 [ℹ]  eksctl version ...
2023-08-20 07:59:14 [ℹ]  using region us-west-2 ...
2023-08-20 07:59:14 [ℹ]  subnets for us-west-2a ...
2023-08-20 07:59:14 [ℹ]  subnets for us-west-2b ...
2023-08-20 07:59:14 [ℹ]  subnets for us-west-2c ...
...
2023-08-20 08:14:06 [ℹ]  kubectl command should work with ...
2023-08-20 08:14:06 [✔]  EKS cluster "my-cluster" in "us-west-2" is ready
```

Once the command is done, you should be able to query the the kube API. For
example:

```bash
kubectl get nodes
```

Example output:

```
NAME                      STATUS   ROLES    AGE     VERSION
ip-XXX.compute.internal   Ready    <none>   32m     v1.27.4-eks-2d98532
ip-YYY.compute.internal   Ready    <none>   32m     v1.27.4-eks-2d98532
```

### Create the Node Groups

As per [this section of the Cluster Autoscaler
docs](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md):

> If you’re using Persistent Volumes, your deployment needs to run in the same
> AZ as where the EBS volume is, otherwise the pod scheduling could fail if it
> is scheduled in a different AZ and cannot find the EBS volume. To overcome
> this, either use a single AZ ASG for this use case, or an ASG-per-AZ while
> enabling `--balance-similar-node-groups`.

Based on the above, we will create a node group for each of the availability
zones (AZs) that was declared in `cluster.yaml` so that the Cluster Autoscaler will
always bring up a node in the AZ where a VM's EBS-backed PV is located.

To do that, we will first prepare a template that we can then feed to
`envsubst`. Save the following in `node-group.yaml.template`:

```yaml
---
# See: Config File Schema <https://eksctl.io/usage/schema/>
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${RD_CLUSTER_NAME}
  region: ${RD_REGION}

managedNodeGroups:
  - name: ng-${EKS_AZ}-c5-metal
    amiFamily: AmazonLinux2
    instanceType: c5.metal
    availabilityZones:
      - ${EKS_AZ}
    desiredCapacity: 1
    maxSize: 3
    minSize: 0
    labels:
      alpha.eksctl.io/cluster-name: my-cluster
      alpha.eksctl.io/nodegroup-name: ng-${EKS_AZ}-c5-metal
      workload: vm
    privateNetworking: false
    ssh:
      allow: true
      publicKeyPath: ${RD_EC2_KEYPAIR_NAME}
    volumeSize: 500
    volumeIOPS: 10000
    volumeThroughput: 750
    volumeType: gp3
    propagateASGTags: true
    tags:
      alpha.eksctl.io/nodegroup-name: ng-${EKS_AZ}-c5-metal
      alpha.eksctl.io/nodegroup-type: managed
      k8s.io/cluster-autoscaler/my-cluster: owned
      k8s.io/cluster-autoscaler/enabled: "true"
      # The following tags help CAS determine that this node group is able
      # to satisfy the label and resource requirements of the KubeVirt VMs.
      # See: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
      k8s.io/cluster-autoscaler/node-template/resources/devices.kubevirt.io/kvm: "1"
      k8s.io/cluster-autoscaler/node-template/resources/devices.kubevirt.io/tun: "1"
      k8s.io/cluster-autoscaler/node-template/resources/devices.kubevirt.io/vhost-net: "1"
      k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage: 50M
      k8s.io/cluster-autoscaler/node-template/label/kubevirt.io/schedulable: "true"
```

The last few tags bears additional emphasis. They are required because when a
virtual machine is created, it will have the following requirements:


```yaml
requests:
  devices.kubevirt.io/kvm: 1
  devices.kubevirt.io/tun: 1
  devices.kubevirt.io/vhost-net: 1
  ephemeral-storage: 50M

nodeSelectors: kubevirt.io/schedulable=true
```

However, at least when scaling from zero for the first time, CAS will have no
knowledge of this information unless the correct AWS tags are added to the node
group. This is why we have the following added to the managed node group's
tags:


```yaml
k8s.io/cluster-autoscaler/node-template/resources/devices.kubevirt.io/kvm: "1"
k8s.io/cluster-autoscaler/node-template/resources/devices.kubevirt.io/tun: "1"
k8s.io/cluster-autoscaler/node-template/resources/devices.kubevirt.io/vhost-net: "1"
k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage: 50M
k8s.io/cluster-autoscaler/node-template/label/kubevirt.io/schedulable: "true"
```

> For more information on these tags, see [Auto-Discovery
> Setup](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup).

### Create the VM Node Groups

We can now create the node group:

```bash
yq .availabilityZones[] cluster.yaml -r | \
    xargs -I{} bash -c "
        export EKS_AZ={};
        envsubst < node-group.yaml.template | \
        eksctl create nodegroup --config-file -
    "
```

## Deploy KubeVirt

> The following was adapted from [KubeVirt quickstart with cloud
> providers](https://kubevirt.io/quickstart_cloud/).

Deploy the KubeVirt operator:

```bash
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/v1.0.0/kubevirt-operator.yaml
```

So that the operator will know how to deploy KubeVirt, let's add the `KubeVirt`
resource:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  certificateRotateStrategy: {}
  configuration:
    developerConfiguration:
      featureGates: []
  customizeComponents: {}
  imagePullPolicy: IfNotPresent
  workloadUpdateStrategy: {}
  infra:
    nodePlacement:
      nodeSelector:
        workload: infra
      tolerations:
        - key: CriticalAddonsOnly
          operator: Exists
EOF
```

> Notice how we are specifically configuring KubeVirt itself to tolerate the
> `CriticalAddonsOnly` taint. This is so that the KubeVirt services themselves
> can be scheduled in the infra nodes instead of the bare metal nodes which we
> want to scale down to zero when there are no VMs.

Wait until KubeVirt is in a `Deployed` state:

```bash
kubectl get -n kubevirt -o=jsonpath="{.status.phase}" \
	kubevirt.kubevirt.io/kubevirt
```

Example output:

```
Deployed
```

Double check that all KubeVirt components are healthy:

```bash
kubectl get pods -n kubevirt
```

Example output:

```
NAME                                 READY   STATUS    RESTARTS       AGE
pod/virt-api-674467958c-5chhj        1/1     Running   0              98d
pod/virt-api-674467958c-wzcmk        1/1     Running   0              5d
pod/virt-controller-6768977b-49wwb   1/1     Running   0              98d
pod/virt-controller-6768977b-6pfcm   1/1     Running   0              5d
pod/virt-handler-4hztq               1/1     Running   0              5d
pod/virt-handler-x98x5               1/1     Running   0              98d
pod/virt-operator-85f65df79b-lg8xb   1/1     Running   0              5d
pod/virt-operator-85f65df79b-rp8p5   1/1     Running   0              98d
```

## Deploy a VM to test

> The following is copied from
> [kubevirt.io](https://kubevirt.io/user-guide/virtual_machines/accessing_virtual_machines/#static-ssh-public-key-injection-via-cloud-init).

First create a secret from your public key:

```bash
kubectl create secret generic my-pub-key --from-file=key1=~/.ssh/id_rsa.pub
```

Next, create the VM:

```bash
# Create a VM referencing the Secret using propagation method configDrive
cat <<EOF | kubectl create -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          rng: {}
        resources:
          requests:
            memory: 1024M
      terminationGracePeriodSeconds: 0
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: my-pub-key
          propagationMethod:
            configDrive: {}
      volumes:
      - containerDisk:
          image: quay.io/containerdisks/fedora:latest
        name: containerdisk
      - cloudInitConfigDrive:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
        name: cloudinitdisk
EOF
```

Check that the test VM is running:

```bash
kubectl get vm
```

Example output:

```
NAME        AGE     STATUS               READY
testvm      30s     Running              True
```

Delete the VM:

```bash
kubectl delete testvm
```

## Set Up Cluster Autoscaler

### Prepare the permissions for Cluster Autoscaler

So that CAS can set the desired capacity of each node group dynamically, we
must grant it limited access to certain AWS resources. The first step to this
is to define the IAM policy.

> This section is based off of the "Create an IAM policy and role" section of
> the [AWS
> Autoscaling](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html)
> documentation.

### Create the cluster-specific policy document

Prepare the policy document by rendering the following file.


```bash
cat > policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeAutoScalingGroups",
                "ec2:DescribeLaunchTemplateVersions",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations",
                "ec2:DescribeInstanceTypes"
            ],
            "Resource": "*"
        }
    ]
}
EOF
```

The above should be enough for CAS to do its job. Next, create the policy:

```bash
aws iam create-policy \
    --policy-name eks-${RD_REGION}-${RD_CLUSTER_NAME}-ClusterAutoscalerPolicy \
    --policy-document file://policy.json
```

> IMPORTANT: Take note of the returned policy ARN. You will need that below.

### Create the IAM role and k8s service account pair

The Cluster Autoscaler needs a service account in the k8s cluster that's
associated with an IAM role that consumes the policy document we created in the
previous section. This is normally a two-step process but can be created in a
single command using `eksctl`:

> For more information on what `eksctl` is doing under the covers, see [How It
> Works](https://eksctl.io/usage/iamserviceaccounts/#how-it-works) from the
> `eksctl` documentation for IAM Roles for Service Accounts.

```bash
export RD_POLICY_ARN="<Get this value from the last command's output>"

eksctl create iamserviceaccount \
	--cluster=${RD_CLUSTER_NAME} \
	--region=${RD_REGION} \
	--namespace=kube-system \
	--name=cluster-autoscaler \
	--attach-policy-arn=${RD_POLICY_ARN} \
	--override-existing-serviceaccounts \
	--approve
```

Double check that the `cluster-autoscaler` service account has been correctly
annotated with the IAM role that was created by `eksctl` in the same step:

```bash
kubectl get sa cluster-autoscaler -n kube-system -ojson | \
	jq -r '.metadata.annotations | ."eks.amazonaws.com/role-arn"'
```

Example output:

```
arn:aws:iam::365499461711:role/eksctl-my-cluster-addon-iamserviceaccount-...
```

Check from the AWS Console if the above role contains the policy that we created
earlier.

### Deploy Cluster Autoscaler

First, find the most recent Cluster Autoscaler version that has the same MAJOR
and MINOR version as the kubernetes cluster you're deploying to.

Get the kube cluster's version:

```bash
kubectl version -ojson | jq -r .serverVersion.gitVersion
```

Example output:

```
v1.27.4-eks-2d98532
```

Choose the appropriate version for CAS. You can get the latest Cluster
Autoscaler versions from its [Github Releases
Page](https://github.com/kubernetes/autoscaler/releases?q=cluster-autoscaler+1&expanded=true).

Example:

```bash
export CLUSTER_AUTOSCALER_VERSION=1.27.3
```

Next, deploy the cluster autoscaler using the deployment template that I
prepared in the [companion
repo](https://github.com/relaxdiego/kubevirt-cas-baremetal)

```bash
envsubst < <(curl https://raw.githubusercontent.com/relaxdiego/kubevirt-cas-baremetal/main/cas-deployment.yaml.template) | \
  kubectl apply -f -
```

Check the cluster autoscaler status:

```bash
kubectl get deploy,pod -l app=cluster-autoscaler -n kube-system
```

Example output:

```
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cluster-autoscaler   1/1     1            1           4m1s

NAME                                      READY   STATUS    RESTARTS   AGE
pod/cluster-autoscaler-6c58bd6d89-v8wbn   1/1     Running   0          60s
```

Tail the `cluster-autoscaler` pod's logs to see what's happening:

```bash
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
```

Below are example log entries from Cluster Autoscaler terminating an unneeded
node:

```
node ip-XXXX.YYYY.compute.internal may be removed
...
ip-XXXX.YYYY.compute.internal was unneeded for 1m3.743475455s
```

Once the timeout has been reached (default: 10 minutes), CAS will scale down
the group:

```
Scale-down: removing empty node ip-XXXX.YYYY.compute.internal
Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", ...
Successfully added ToBeDeletedTaint on node ip-XXXX.YYYY.compute.internal
Terminating EC2 instance: i-ZZZZ
DeleteInstances was called: ...
```

> For more information on how Cluster Autoscaler scales down a node group, see
> [How does scale-down
> work?](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-scale-down-work)
> from the project's FAQ.

When you try to get the list of nodes, you should see the bare metal nodes
tainted such that they are no longer schedulable:

```
NAME       STATUS                     ROLES    AGE    VERSION
ip-XXXX    Ready,SchedulingDisabled   <none>   70m    v1.27.3-eks-a5565ad
ip-XXXX    Ready,SchedulingDisabled   <none>   70m    v1.27.3-eks-a5565ad
ip-XXXX    Ready,SchedulingDisabled   <none>   70m    v1.27.3-eks-a5565ad
ip-XXXX    Ready                      <none>   112m   v1.27.3-eks-a5565ad
ip-XXXX    Ready                      <none>   112m   v1.27.3-eks-a5565ad
```

In a few more minutes, the nodes will be deleted.

To try the scale up, just deploy a VM.

```
Expanding Node Group eks-ng-eacf8ebb ...
Best option to resize: eks-ng-eacf8ebb
Estimated 1 nodes needed in eks-ng-eacf8ebb
Final scale-up plan: [{eks-ng-eacf8ebb 0->1 (max: 3)}]
Scale-up: setting group eks-ng-eacf8ebb size to 1
Setting asg eks-ng-eacf8ebb size to 1
```

## Done

At this point you should have a working, auto-scaling EKS cluster that can host
VMs on bare metal nodes. If you have any questions, ask them
[here](https://github.com/relaxdiego/relaxdiego.github.com/discussions/new?category=general).

## References

- [Amazon EKS Autoscaling](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html)
- [Cluster Autoscaler in Plain English](https://aws.plainenglish.io/cluster-autoscaler-amazon-eks-7ffaa24e5938)
- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [eksctl create iamserviceaccount](https://eksctl.io/usage/iamserviceaccounts/)
