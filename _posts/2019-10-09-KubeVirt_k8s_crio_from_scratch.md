---
layout: post
author: Pedro Ibáñez Requena
description: How to setup a home lab environment with Kubernetes, CRI-O and KubeVirt step by step guide
navbar_active: Blogs
category: news
comments: true
title: KubeVirt on Kubernetes with CRI-O from scratch
pub-date: October
pub-year: 2019
---

Building your environment for testing or automation purposes can be difficult when using different edge technologies, in this guide you'll find how to set up your system step-by-step to work with the latest versions up to today of Kubernetes, CRI-O and KubeVirt.
In this series of blogposts the following topics are going to be covered en each post:
* Requirements: dependencies and containers runtime
* [Kubernetes: Cluster and Network](https://kubevirt.io/2019/KubeVirt_k8s_crio_from_scratch_installing_kubernetes.html)
* KubeVirt: requirements and first Virtual Machine

## Pre-requisites
### Versions
The following versions are going to be used:

| Software      | Purpose  |  Version       |
| ------------- | ---------- | :-------------:|
| CentOS        | Operating System | 7.7.1908      |
| Kubernetes    | Orchestration | v1.16.0       |
| CRI-O         | Containers runtime | 1.16.0-dev    |
| KubeVirt      | Virtual Machine Management on Kubernetes | v0.20.7       |
| Ansible (optional)     | Automation tool | 2.8.4         |


### Requirements
It is a requirement to have a VM with enough resources, the OS running this VM as indicated in the table above has to be CentOS 7.7.1908 and you should take care of its deployment. In this guide the system will be named k8s-test.local and the IP address is 192.168.0.10. A second system called laptop would be used to run the playbooks (if you choose to go the easy and automated way).

It is also needed to have access to the root account in the VM for installing the required software and configure some kernel parameters. In this example only a Kubernetes master would be used.

## Instructions
### Preparing the VM
Ensure the VM system is updated to the latest versions of the software and also ensure that the epel repository is installed:
```
k8s-test.local# yum install epel-release -y

k8s-test.local# yum update -y

k8s-test.local# yum install vim jq -y
```
The following kernel parameters have to be configured:
```
k8s-test.local# cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

And also the following kernel modules have to be installed:
```
k8s-test.local# modprobe br_netfilter
k8s-test.local# echo br_netfilter > /etc/modules-load.d/br_netfilter.conf

k8s-test.local# modprobe overlay
k8s-test.local# echo overlay > /etc/modules-load.d/overlay.conf
```

The new sysctl parameters have to be loaded in the system with the following command:
```
k8s-test.local# sysctl -p/etc/sysctl.d/99-kubernetes-cri.conf
```

The next step is to disable SELinux:
```
k8s-test.local# setenforce 0

k8s-test.local# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```
And the installation of Kubernetes and CRI-O can proceed.

### Installing Kubernetes and CRI-O
To install Kubernetes and CRI-O several ways can be used, in this guide there is the step-by-step guide where the user can do everything by himself or the alternative option, taking the easy road and running the ansible-playbook that will take care of almost everything.

#### The ansible way
Note: we are waiting for the [PR](https://github.com/cri-o/cri-o-ansible/pull/25) to be merged in the official cri-o-ansible repository, meantime a fork in an alternative repository would be used. Also, note that the following commands are executed from a different place, in this case from a computer called `laptop`:
```
laptop$ sudo yum install ansible -y

laptop# git clone https://github.com/ptrnull/cri-o-ansible

laptop# cd cri-o-ansible

laptop# git checkout fixes_k8s_1_16

laptop# ansible-playbook cri-o.yml -i 192.168.0.10,
```

Once the playbook ends the system would be ready for getting CRI-O configured.

#### The step-by-step way
If the ansible way was chosen, you may want to skip this section. Otherwise, let's configure each piece.

The required packages may be installed in the system running the following command:
```
k8s-test.local# yum install btrfs-progs-devel container-selinux device-mapper-devel gcc git glib2-devel glibc-devel glibc-static gpgme-devel json-glib-devel libassuan-devel libgpg-error-devel libseccomp-devel make pkgconfig skopeo-containers tar wget -y
```

Install golang and the md2man packages:
> Note: depending on the operating system running in your VM, it may be needed to change the name of the md2man golang package.
```
k8s-test.local# yum install golang-github-cpuguy83-go-md2man golang -y
```

The following directories have to be created:
* /usr/local/go
* /etc/systemd/system/kubelet.service.d/
* /var/lib/etcd
* /etc/cni/net.d
```
k8s-test.local# for d in "/usr/local/go /etc/systemd/system/kubelet.service.d/ /var/lib/etcd /etc/cni/net.d /etc/containers"; do mkdir -p $d; done
```

Clone the runc repository:
```
k8s-test.local# git clone https://github.com/opencontainers/runc /root/src/github.com/opencontainers/runc
```

Clone the CRI-O repository:
```
k8s-test.local# git clone https://github.com/cri-o/cri-o /root/src/github.com/cri-o/cri-o
```

Clone the CNI repository:
```
k8s-test.local# git clone https://github.com/containernetworking/plugins /root/src/github.com/containernetworking/plugins
```

To build each part, a series of commands have to be executed, first building runc:
```
k8s-test.local# cd /root/src/github.com/opencontainers/runc

k8s-test.local# export GOPATH=/root

k8s-test.local# make BUILDTAGS="seccomp selinux"

k8s-test.local# make install
```

And also runc has to be linked in the correct path:
```
k8s-test.local# ln -sf /usr/local/sbin/runc /usr/bin/runc
```

Now building CRI-O (special focus on switching the branch):
```
k8s-test.local# export GOPATH=/root

k8s-test.local# export GOBIN=/usr/local/go/bin

k8s-test.local# export PATH=/usr/local/go/bin:$PATH

k8s-test.local# cd /root/src/github.com/cri-o/cri-o

k8s-test.local# git checkout release-1.16

k8s-test.local# make

k8s-test.local# make install

k8s-test.local# make install.systemd

k8s-test.local# make install.config
```

CRI-O also needs the conmon software as a dependency:
```
k8s-test.local# git clone http://github.com/containers/conmon /root/src/github.com/conmon

k8s-test.local# cd /root/src/github.com/conmon

k8s-test.local# make

k8s-test.local# make install
```

Now, the ContainerNetworking plugins have to be built and installed:
```
k8s-test.local# cd /root/src/github.com/containernetworking/plugins

k8s-test.local# ./build_linux.sh

k8s-test.local# mkdir -p /opt/cni/bin

k8s-test.local# cp bin/* /opt/cni/bin/
```

The cgroup manager has to be changed in the CRI-O configuration from the value of `systemd` to `cgroupfs`, to get it done, the file `/etc/crio/crio.conf` has to be edited and the variable `cgroup_manager` has to be replaced from its original value of `systemd` to `cgroupfs` (it could be already set it up to that value, in that case this step can be skiped):
```
k8s-test.local# vim /etc/crio/crio.conf
# group_manager = "systemd"
group_manager = "cgroupfs"
```

In the same file, the storage_driver is not configured, the variable `storage_driver` has to be uncommented and the value has to be changed from `overlay` to `overlay2`:
```
k8s-test.local# vim /etc/crio/crio.conf
#storage_driver = "overlay"
storage_driver = "overlay2"
```

Also related with the storage, the `storage_option` has to be configured to have the following value:
```
k8s-test.local# vim /etc/crio/crio.conf
storage_option = [ "overlay2.override_kernel_check=1" ]
```

### Preparing CRI-O
CRI-O is the lightweight container runtime for Kubernetes. As it is pointed in the [CRI-O Website](https://cri-o.io):

>CRI-O is an implementation of the Kubernetes CRI (Container Runtime Interface) to enable using OCI (Open Container Initiative) compatible runtimes. It is a lightweight alternative to using Docker as the runtime for Kubernetes. It allows Kubernetes to use any OCI-compliant runtime as the container runtime for running pods. Today it supports runc and Kata Containers as the container runtimes but any OCI-conformant runtime can be plugged in principle.

>CRI-O supports OCI container images and can pull from any container registry. It is a lightweight alternative to using Docker, Moby or rkt as the runtime for Kubernetes.

The first step is to change the configuration of the `network_dir` parameter in the CRI-O configuration file, for doing so, the `network_dir` parameter in the `/etc/crio/crio.conf` file has to be changed to point to `/etc/crio/net.d`
```
k8s-test.local$ vim /etc/crio/crio.conf
[crio.network]
# Path to the directory where CNI configuration files are located.
network_dir = "/etc/crio/net.d/"
```
Also that directory has to be created:
```
k8s-test.local$ mkdir /etc/crio/net.d
```
The reason behind that change is because CRI-O and `kubeadm reset` don't play well together, as `kubeadm reset` empties /etc/cni/net.d/. Therefore, it is good to change the `crio.network.network_dir` in `crio.conf` to somewhere kubeadm won't touch. To get more information the following link [Running CRI-O with kubeadm] in the References section can be checked.

Now Kubernetes has to be configured to be able to talk to CRI-O, to proceed, a new file has to be created in `/etc/default/kubelet` with the following content:
```
KUBELET_EXTRA_ARGS=--feature-gates="AllAlpha=false,RunAsGroup=true" --container-runtime=remote --cgroup-driver=cgroupfs --container-runtime-endpoint='unix:///var/run/crio/crio.sock' --runtime-request-timeout=5m
```
Now the systemd has to be reloaded reloaded:
```
k8s-test.local# systemctl daemon-reload
```

CRI-O will use flannel network as it is recommended for multus so the following file has to be downloaded and configured:
```
k8s-test.local# cd /etc/crio/net.d/

k8s-test.local# wget https://raw.githubusercontent.com/cri-o/cri-o/master/contrib/cni/10-crio-bridge.conf

k8s-test.local# sed -i 's/10.88.0.0/10.244.0.0/g' 10-crio-bridge.conf

```
As the previous code block has shown, the network used is 10.244.0.0, now the crio service can be started and enabled:
```
k8s-test.local# systemctl enable crio
k8s-test.local# systemctl start crio
k8s-test.local# systemctl status crio
● crio.service - Container Runtime Interface for OCI (CRI-O)
   Loaded: loaded (/usr/local/lib/systemd/system/crio.service; enabled; vendor preset: disabled)
   Active: active (running) since mié 2019-10-02 16:17:06 CEST; 3s ago
     Docs: https://github.com/cri-o/cri-o
 Main PID: 15427 (crio)
   CGroup: /system.slice/crio.service
           └─15427 /usr/local/bin/crio

oct 02 16:17:06 k8s-test systemd[1]: Starting Container Runtime Interface for OCI (CRI-O)...
oct 02 16:17:06 k8s-test systemd[1]: Started Container Runtime Interface for OCI (CRI-O).
```

In the next posts, the [Kubernetes cluster will be set up](https://kubevirt.io/2019/KubeVirt_k8s_crio_from_scratch_installing_kubernetes.html), together with the pod Network and also the KubeVirt with the virtual Machines deployments.
