---
layout: post
author: mhenriks
description: Hello KubeVirt on MiniKube
navbar_active: Blogs
pub-date: June 20
pub-year: 2018
category: uncategorized
comments: true
tags: [kvm, minikube, qemu]
---

In this blog post, we will demonstrate the process for creating and managing virtual machines in Kubernetes with KubeVirt. We will also go through the process of installing [Minikube](https://kubernetes.io/docs/setup/minikube/) and KubeVirt on a Fedora 28 workstation.

<!-- more -->

## Install KVM

MiniKube will create a single node Kubernetes cluster in a KVM virtual machine on our Fedora host. KVM is also the virtualization technology used by KubeVirt so we have to make sure that the host is configured to support nested virtual machines. Fedora does not have that feature enabled by default.

```bash
# install packages
$ sudo yum install libvirt-daemon-kvm qemu-kvm

# enable nested virtualization
# substitute 'kvm_intel' with 'kvm_amd' if your system has an AMD processor
$ sudo modprobe -r kvm_intel
$ sudo vi /etc/modprobe.d/kvm.conf
# uncomment 'options kvm_intel nested=1' and save
$ sudo modprobe kvm_intel

#verify nested virtualization enabled
$ cat /sys/module/kvm_intel/parameters/nested
Y
```

## Install KVM2 driver for Minikube

Minikube requires a special driver to manage Docker Machine VMs running in KVM. KVM2 is the latest iteration of the driver. Read more about it [here](https://minikube.sigs.k8s.io/docs/drivers/kvm2/)

```bash
# install driver to /usr/local/bin
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2 && chmod +x docker-machine-driver-kvm2 && sudo mv docker-machine-driver-kvm2 /usr/local/bin/
```

## Install Minikube

Minikube is responsible for creating and managing a local single-node Kubernetes cluster. It is installed as a single executable.

```bash
#install minikube to /usr/local/bin
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

## Start Minikube

```bash
$ minikube start --vm-driver kvm2 --network-plugin cni
```

## Install kubectl

Now that we have a Kubernetes cluster running, we need some way to communicate with it. That is where the kubectl CLI comes in.

```bash
# install kubectl to /usr/local/bin
$ curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/{{ site.kubernetes_version }}/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# try out the cli
# should see similar output
$ kubectl get all
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5m
```

You may be wondering how kubectl knows where to look for the Kubernetes API endpoint. `minikube start` actually takes care of creating the kubectl configuration file. Take a look at `~/.kube/config`

## Deploy KubeVirt

Get KubeVirt components running on the Kubernetes cluster.

```bash
$ kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/{{ site.kubevirt_version }}/kubevirt.yaml

# watch for KubeVirt components to start (bebin with 'virt-')
# may take awhile as containers are downloaded and started
$ watch kubectl get --all-namespaces pods

# eventually output should look something like this (everything with Running status)
NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
kube-system   etcd-minikube                           1/1	Running   0          16m
kube-system   kube-addon-manager-minikube             1/1	Running   0          15m
kube-system   kube-apiserver-minikube                 1/1	Running   0          15m
kube-system   kube-controller-manager-minikube        1/1	Running   0          16m
kube-system   kube-dns-86f4d74b45-ppp5p               3/3	Running   0          16m
kube-system   kube-proxy-rjkxl                        1/1	Running   0          16m
kube-system   kube-scheduler-minikube                 1/1	Running   0          16m
kube-system   kubernetes-dashboard-5498ccf677-8zmnk   1/1	Running   0          16m
kube-system   storage-provisioner                     1/1	Running   0          16m
kube-system   virt-api-7797f95869-dwrrc               1/1	Running   0          2m
kube-system   virt-api-7797f95869-fqnhk               1/1	Running   1          2m
kube-system   virt-controller-69cc6b4897-nlffm        1/1	Running   0          2m
kube-system   virt-controller-69cc6b4897-xsxmt        1/1	Running   0          2m
kube-system   virt-handler-f7str                      1/1	Running   0          2m
```

## Install virtctl

Virtctl is the CLI for creating and managing KubeVirt virtual machines.

```bash
# install virtctl to /usr/local/bin
$ curl -Lo virtctl https://github.com/kubevirt/kubevirt/releases/download/{{ site.kubevirt_version }}/virtctl-{{ site.kubevirt_version }}-linux-amd64 && chmod +x virtctl && sudo mv virtctl /usr/local/bin
```

## Create a VM

Apply manifest for VM. If you're curious, download the manifest file locally and take a look.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml

# check that VM successfully created
$ kubectl get vms
NAME      AGE
testvm    7s
# for more detailed info, run
$ kubectl get vms -o yaml testvm
```

## Start a VM

Time to try out virtctl.

```bash
$ virtctl start testvm

# wait for VM to be running
$ watch kubectl get pods

# confirm with kubectl
$ kubectl get vmis
NAME      AGE
testvm    4s

# for more detailed info
$ kubectl get vmis -o yaml testvm
```

## Connect to VM

The VM is running CirrOS, which is "a Tiny OS that specializes in running on a cloud." Don't expect anything fancy. Look [here](https://launchpad.net/cirros) for more info on CirrOS

```bash
$ virtctl console testvm

# note escape sequence of '^]'
# login with creds provided and poke around
# you are connected to a VM running in Kubernetes!  Pretty cool!
# 'exit' to logout
# quit virtctl by providing escape sequence '^]
```

## Stop a VM

```bash
$ virtctl stop testvm

# wait for termination to complete
$ watch kubectl get pods

# confirm with kubectl
$ kubectl get vmis
No resources found.
```

## Delete a VM

```bash
$ kubectl delete vms testvm

# confirm with kubectl
$ kubectl get vms
No resources found.
```

## Next Steps

Take a look at the [user guide](https://kubevirt.io/user-guide/#/) and get involved with the [community](http://kubevirt.io/community/).
