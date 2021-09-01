---
layout: post
author: Pedro Ibáñez Requena
description: How to setup a home lab environment with Kubernetes, CRI-O and KubeVirt step by step guide - Installing KubeVirt
navbar_active: Blogs
category: news
comments: true
title: KubeVirt on Kubernetes with CRI-O from scratch - Installing KubeVirt
pub-date: October 23
pub-year: 2019
tags: [cri-o, kubevirt installation]
---

Building your environment for testing or automation purposes can be difficult when using different technologies. In this guide, you'll find how to set up your system step-by-step to work with the latest versions of Kubernetes (up to today), CRI-O and KubeVirt.

In this series of blogposts the following topics are going to be covered en each post:

- [Requirements: dependencies and containers runtime]({% post_url 2019-10-09-KubeVirt_k8s_crio_from_scratch %})
- [Kubernetes: Cluster and Network]({% post_url 2019-10-16-KubeVirt_k8s_crio_from_scratch_installing_kubernetes %})
- [KubeVirt: requirements and first Virtual Machine]({% post_url 2019-10-23-KubeVirt_k8s_crio_from_scratch_installing_KubeVirt %})

In the first blogpost of the series ([KubeVirt on Kubernetes with CRI-O from scratch)]({% post_url 2019-10-09-KubeVirt_k8s_crio_from_scratch %}) the initial set up for a CRI-O runtime environment has been covered.

In the second blogpost of the series ([Kubernetes: Cluster and Network]({% post_url 2019-10-16-KubeVirt_k8s_crio_from_scratch_installing_kubernetes %})) the Kubernetes cluster and network were set up based on the CRI-O installation already prepared in the first post.

This is the last blogpost of the series of 3, in this case KubeVirt is going to be installed and also would be used to deploy an example Virtual Machine.

## Installing KubeVirt

What is KubeVirt? if you navigate to the [KubeVirt webpage](https://kubevirt.io) you can read:

> KubeVirt technology addresses the needs of development teams that have adopted or want to adopt Kubernetes but possess existing Virtual Machine-based workloads that cannot be easily containerized. More specifically, the technology provides a unified development platform where developers can build, modify, and deploy applications residing in both Application Containers as well as Virtual Machines in a common, shared environment.
> Benefits are broad and significant. Teams with a reliance on existing virtual machine-based workloads are empowered to rapidly containerize applications. With virtualized workloads placed directly in development workflows, teams can decompose them over time while still leveraging remaining virtualized components as is comfortably desired.

In this example there is a Kubernetes cluster compose of one master, for it to be schedulable to host the KubeVirt pods, a little modification has to be done:

```sh
k8s-test.local# kubectl taint nodes k8s-test node-role.kubernetes.io/master:NoSchedule-
```

The last version of KubeVirt at the moment is `v0.20.8`, to check it the following command can be executed:

```sh
k8s-test.local# export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | jq -r .tag_name)

k8s-test.local# echo $KUBEVIRT_VERSION
v0.20.8
```

To install KubeVirt, the operator and the cr are going to be created with the following commands:

```sh
k8s-test.local# kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml

k8s-test.local# kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
```

This demo environment already runs within a virtualized environment, and in order to be able to run VMs here we need to pre-configure KubeVirt so it uses software-emulated virtualization instead of trying to use real hardware virtualization.

```sh
k8s-test.local# kubectl create configmap kubevirt-config -n kubevirt --from-literal debug.useEmulation=true
```

The deployment can be checked with the following command:

```sh
k8s-test.local# kubectl get pods -n kubevirt
NAME                               READY   STATUS    RESTARTS   AGE
virt-api-5546d58cc8-5sm4v          1/1     Running   0          16h
virt-api-5546d58cc8-pxkgt          1/1     Running   0          16h
virt-controller-5c749d77bf-cxxj8   1/1     Running   0          16h
virt-controller-5c749d77bf-wwkxm   1/1     Running   0          16h
virt-handler-cx7q7                 1/1     Running   0          16h
virt-operator-6b4dccb44d-bqxld     1/1     Running   0          16h
virt-operator-6b4dccb44d-m2mvf     1/1     Running   0          16h
```

Now that KubeVirt is installed is the right time to download the client tool to interact with th Virtual Machines.

```sh
k8s-test.local# wget -O virtctl https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64

k8s-test.local# chmod +x virtctl

k8s-test.local# ./virtctl
Available Commands:
  console      Connect to a console of a virtual machine instance.
  expose       Expose a virtual machine instance, virtual machine, or virtual machine instance replica set as a new service.
  help         Help about any command
  image-upload Upload a VM image to a PersistentVolumeClaim.
  restart      Restart a virtual machine.
  start        Start a virtual machine.
  stop         Stop a virtual machine.
  version      Print the client and server version information.
  vnc          Open a vnc connection to a virtual machine instance.

Use "virtctl <command> --help" for more information about a given command.
Use "virtctl options" for a list of global command-line options (applies to all commands).
```

This step is optional, right now anything related with the Virtual Machines can be done running the `virtctl` command. In case there's a need to interact with the Virtual Machines without leaving the scope of the `kubectl` command, the virt plugin for Krew can be installed following the instructions below:

```sh
k8s-test.local# (
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.3.1/krew.{tar.gz,yaml}" &&
  tar zxvf krew.tar.gz &&
  ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
    --manifest=krew.yaml --archive=krew.tar.gz
)
...
Installed plugin: krew
WARNING: You installed a plugin from the krew-index plugin repository.
   These plugins are not audited for security by the Krew maintainers.
   Run them at your own risk.
```

The warning printed by the Krew maintainers can be ignored.
To have the krew plugin available, the PATH variable has to be modified:

```sh
k8s-test.local# vim ~/.bashrc
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
k8s-test.local# source ~/.bashrc
```

Now, the virt plugin is going to be installed using the krew plugin manager:

```sh
k8s-test.local# kubectl krew install virt
Updated the local copy of plugin index.
Installing plugin: virt
CAVEATS:
\
 |  virt plugin is a wrapper for virtctl originating from the KubeVirt project. In order to use virtctl you will
 |  need to have KubeVirt installed on your Kubernetes cluster to use it. See https://kubevirt.io/ for details
 |
 |  Run
 |
 |    kubectl virt help
 |
 |  to get an overview of the available commands
 |
 |  See
 |
 |    https://kubevirt.io/user-guide/virtual_machines/graphical_and_console_access/
 |
 |  for a usage example
/
Installed plugin: virt
WARNING: You installed a plugin from the krew-index plugin repository.
   These plugins are not audited for security by the Krew maintainers.
   Run them at your own risk.
```

## Installing the first Virtual Machine in KubeVirt

For this example, a cirros Virtual Machine is going to be created, in this example, the kind of disk used is a registry disk (not persistent):

```sh
k8s-test.local# kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml

k8s-test.local# kubectl get vms
NAME        AGE   RUNNING   VOLUME
testvm   13s   false
```

After the Virtual Machine has been created, it has to be started, to do so, the virtctl or the kubectl can be used (depending on what method has been chosen in previous steps).

```sh
k8s-test.local# ./virtctl start testvm
VM vm-cirros was scheduled to start

k8s-test.local# kubectl get vms
NAME        AGE     RUNNING   VOLUME
testvm   7m11s   true
```

Next thing to do is to use the `kubectl` command for getting the IP address and the actual status of the virtual machines:

```sh
k8s-test.local# kubectl get vmis
kubectl get vmis
NAME        AGE    PHASE        IP    NODENAME
testvm    14s   Scheduling

k8s-test.local# kubectl get vmis
NAME     AGE   PHASE     IP            NODENAME
testvm   63s   Running   10.244.0.15   k8s-test
```

So, finally the Virtual Machine is running and has an IP address. To connect to that VM, the console can be used (`./virtctl console testvm`) or also a direct connection with SSH can be made:

```sh
k8s-test.local# ssh cirros@10.244.0.15
cirros@10.244.0.15's password: gocubsgo
$ uname -a
Linux testvm 4.4.0-28-generic #47-Ubuntu SMP Fri Jun 24 10:09:13 UTC 2016 x86_64 GNU/Linux
$ exit
```

To stop the Virtual Machine one of the following commands can be executed:

```sh
k8s-test.local# ./virtctl stop testvm
VM testvm was scheduled to stop

k8s-test.local# kubectl virt stop testvm
VM testvm was scheduled to stop
```

## Troubleshooting

Each step of this guide has a place where to look for possible issues, in general, the [troubleshooting guide of kubernetes](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/) can be checked. The following list tries to ease the possible troubleshooting in case of problems during each step of this guide:

- CRI-O: check the status of the CRI-O service `systemctl status crio` and also the messages in the journal `journalctl -u crio -lf`
- Kubernetes: check the status of the Kubelet service `systemctl status kubelet` and also the messages in the journal `journalctl -u kubelet -fl`
- Pods: for checking the status of the pods the kubectl command can be used in different ways
  - `kubectl get pods -A`
  - `kubectl describe pod $pod`
- Nodes: a `Ready` status would mean everything is ok with the node, otherwise the details of that node can be checked.
  - `kubectl get nodes -o wide`
  - `kubectl get node <nodename> -o yaml`
- KubeVirt: to check the status of the KubeVirt pods use `kubectl get pods -n kubevirt`

## References

- [Kubernetes getting started](https://kubernetes.io/docs/setup/)
- [Kubernetes installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Running CRI-O with kubeadm](https://github.com/cri-o/cri-o/blob/master/tutorials/kubeadm.md#configuring-cni)
- [Kubernetes pod-network configuration](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)
- [Kubectl cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Multus](https://github.com/intel/multus-cni)
- [KubeVirt User Guide](https://kubevirt.io/user-guide/)
- [KubeVirt Katacoda scenarios](https://www.katacoda.com/kubevirt)
