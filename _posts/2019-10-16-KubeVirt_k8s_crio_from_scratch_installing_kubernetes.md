---
layout: post
author: Pedro Ibáñez Requena
description: How to setup a home lab environment with Kubernetes, CRI-O and KubeVirt step by step guide - Installing Kubernetes
navbar_active: Blogs
category: news
comments: true
title: KubeVirt on Kubernetes with CRI-O from scratch - Installing Kubernetes
pub-date: Oct 16
pub-year: 2019
---

Building your environment for testing or automation purposes can be difficult when using different edge technologies, in this guide you'll find how to set up your system step-by-step to work with the latest versions of Kubernetes (up to today), CRI-O and KubeVirt.

In this series of blogposts the following topics are going to be covered en each post:

* [Requirements: dependencies and containers runtime]({% post_url 2019-10-09-KubeVirt_k8s_crio_from_scratch %})
* [Kubernetes: Cluster and Network]({% post_url 2019-10-16-KubeVirt_k8s_crio_from_scratch_installing_kubernetes %})
* [KubeVirt: requirements and first Virtual Machine]({% post_url 2019-10-23-KubeVirt_k8s_crio_from_scratch_installing_KubeVirt %})

In the first blogpost of the series ([KubeVirt on Kubernetes with CRI-O from scratch)]({% post_url 2019-10-09-KubeVirt_k8s_crio_from_scratch %}) the initial set up for a CRI-O runtime environment has been covered. In this post is shown the installation and configuration of Kubernetes based in the previous CRI-O environment.

## Installing Kubernetes

If the ansible way was chosen, you may want to skip this section since the repository and needed packages were already installed during execution.

To install the K8s packages a new repo has to be added:

```ini
k8s-test.local# vim /etc/yum.repos.d/kubernetes.repo
[Kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
```

Now, the gpg keys of the packages can be imported into the system and the installation can proceed:

```sh
k8s-test.local# rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

k8s-test.local# yum install -y kubelet kubeadm kubectl
```

Once the Kubelet is configured and CRI-O also ready, the CRI-O daemon can be started and the setup of the cluster can be done:

> Note that kubelet will not start successfully until the Kubernetes cluster is installed.

```sh
k8s-test.local# systemctl restart crio

k8s-test.local# systemctl enable --now kubelet
```

## Installing the Kubernetes cluster

There are multiple ways for installing a Kubernetes cluster, in this example it will be done with the command `kubeadm`, the pod network cidr is the same that has been previously used for the CRI-O bridge in the `10-crio-bridge.conf` configuration file:

```sh
k8s-test.local# kubeadm init --pod-network-cidr=10.244.0.0/16
```

When the installation finishes the command will print a similar message like this one:

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.10:6443 --token 6fsrbi.iqsw1girupbwue5o \
    --discovery-token-ca-cert-hash sha256:c7cf9d9681876856f9b7819067841436831f19004caadab0b5838a9bf7f4126a
```

Now, it's time to deploy the pod network. If the reader is curious and want to already check the status of the cluster, the following commands can be executed for getting all the pods running and their status:

```sh
k8s-test.local# export KUBECONFIG=/etc/kubernetes/kubelet.conf

k8s-test.local# kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-5644d7b6d9-ffnvx           1/1     Running   0          101s
kube-system   coredns-5644d7b6d9-lh9gm           1/1     Running   0          101s
kube-system   etcd-k8s-test                      1/1     Running   0          59s
kube-system   kube-apiserver-k8s-test            1/1     Running   0          54s
kube-system   kube-controller-manager-k8s-test   1/1     Running   0          58s
kube-system   kube-proxy-tdcdv                   1/1     Running   0          101s
kube-system   kube-scheduler-k8s-test            1/1     Running   0          50s
```

## Installing the pod network

The [Kubernetes pod-network documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network) shows different add-on to handle the communications between the pods.

In this example Virtual Machines will be deployed with KubeVirt and also they will have multiple network interfaces attached to the VMs, in this example [Multus](https://github.com/intel/multus-cni) is going to be used.

Some of the [Multus Prequisites](https://github.com/intel/multus-cni/blob/master/doc/quickstart.md) indicate:

> After installing Kubernetes, you must install a default network CNI plugin. If you're using kubeadm, refer to the "Installing a pod network add-on" section in the kubeadm documentation. If it's your first time, we generally recommend using Flannel for the sake of simplicity.

So flannel is going to be installed running the following commands:

```sh
k8s-test.local# cd /root
k8s-test.local# wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

The version of CNI has to be checked and ensured that is the `0.3.1` version, otherwise, it has to be changed, in this example the version `0.2.0` is replaced by the `0.3.1`:

```sh
k8s-test.local# grep cniVersion kube-flannel.yml
      "cniVersion": "0.2.0",

k8s-test.local# sed -i 's/0.2.0/0.3.1/g' kube-flannel.yml

k8s-test.local# kubectl apply -f kube-flannel.yml
podsecuritypolicy.policy/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds-amd64 created
daemonset.apps/kube-flannel-ds-arm64 created
daemonset.apps/kube-flannel-ds-arm created
daemonset.apps/kube-flannel-ds-ppc64le created
daemonset.apps/kube-flannel-ds-s390x created
```

Once the flannel network has been created the Multus can be defined, to check the status of the pods the following command can be executed:

```sh
k8s-test.local# kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-5644d7b6d9-9mfc9           1/1     Running   0          20h
kube-system   coredns-5644d7b6d9-sd6ck           1/1     Running   0          20h
kube-system   etcd-k8s-test                      1/1     Running   0          20h
kube-system   kube-apiserver-k8s-test            1/1     Running   0          20h
kube-system   kube-controller-manager-k8s-test   1/1     Running   0          20h
kube-system   kube-flannel-ds-amd64-ml68d        1/1     Running   0          20h
kube-system   kube-proxy-lqjpv                   1/1     Running   0          20h
kube-system   kube-scheduler-k8s-test            1/1     Running   0          20h
```

To load the multus configuration, the `multus-cni` repository has to be cloned, and also the `kube-1.16-change` branch has to be used:

```sh
k8s-test.local# git clone https://github.com/intel/multus-cni /root/src/github.com/multus-cni

k8s-test.local# cd /root/src/github.com/multus-cni

k8s-test.local# git checkout origin/kube-1.16-change

k8s-test.local# cd multus-cni/images
```

To load the multus daemonset the following command has to be executed:

```sh
k8s-test.local# kubectl create -f multus-daemonset-crio.yml
customresourcedefinition.apiextensions.k8s.io/network-attachment-definitions.k8s.cni.cncf.io created
clusterrole.rbac.authorization.k8s.io/multus created
clusterrolebinding.rbac.authorization.k8s.io/multus created
serviceaccount/multus created
configmap/multus-cni-config created
daemonset.apps/kube-multus-ds-amd64 created
daemonset.apps/kube-multus-ds-ppc64le created
```

In the next post, the KubeVirt requirements will be set up together with the binaries and YAML files and also the first virtual Machines will be deployed.
