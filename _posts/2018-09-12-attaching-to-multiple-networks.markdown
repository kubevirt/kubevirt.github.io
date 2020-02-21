---
layout: post
author: yuvalif
description: This post describes how to connect a Virtual Machine to more than one network using the Multus CNI.
navbar_active: Blogs
pub-date: September 12
pub-year: 2018
category: news
comments: true
tags: [multus, networking, CNI, multiple networks]
---

# Introduction

Virtual Machines often need multiple interfaces connected to different networks. This could be because the application running on it expect to be connected to different interfaces (e.g. a virtual router running on the VM); because the VM need L2 connectivity to a network not managed by Kubernetes (e.g. allow for PXE booting); because an **existing** VM, ported into KubeVirt, runs applications that expect multiple interfaces to exists; or any other reason - which we'll be happy to hear about in the comment section!

In KubeVirt, as nicely explained in this [blog post]({% post_url 2018-04-25-KubeVirt-Network-Deep-Dive %}), there is already a mechanism to take an interface from the pod and move it into the Virtual Machine. However, Kubernetes allows for a single network plugin to be used in a cluster (across all pods), and provide one interface for each pod. This forces us to choose between having pod network connectivity and any other network connectivity for the pod and, in the context of KubeVirt, the Virtual Machine within.

To overcome this limitation, we use [Multus](https://github.com/intel/multus-cni), which is a "meta" CNI (Container Network Interface), allowing multiple CNIs to coexist, and allow for a pod to use the right ones for its networking needs.

# How Does it Work for Pods?

The magic is done via a new CRD (Custom Resource Definition) called `NetworkAttachmentDefinition` introduced by the Multus project, and adopted by the Kubernetes community as the [de-facto standard](https://docs.google.com/document/d/1Ny03h6IDVy_e_vmElOqR7UdTPAG_RNydhVE1Kx54kFQ/edit#heading=h.hylsbqoj5fxd) for attaching pods to one or more networks. These network definition contains a field called `type` which indicates the name of the actual CNI that provide the network, and different configuration payloads which the Multus CNI is passing to the actual CNI. For example, the following network definition:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: a-bridge-network
spec:
  config: '{
    "cniVersion": "0.3.0",
    "name": "a-bridge-network",
    "type": "bridge",
    "bridge": "br0",
    "isGateway": true,
    "ipam": {
     "type": "host-local",
     "subnet": "192.168.5.0/24",
     "dataDir": "/mnt/cluster-ipam"
    }
}'
```

Allows attaching a pod into a network provided by the [bridge CNI](https://github.com/containernetworking/plugins/tree/master/plugins/main/bridge).

Once a pod with the following annotation is created:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: a-bridge-network
spec:
```

The Multus CNI will find out whether a CNI of type `bridge` exists, and invoke it with the rest of the configuration in the CRD.

> note ""
> Even without Multus, this exact configuration could have been put under `/etc/cni/net.d`, and provide the same network to the pod, using the bride CNI. But, in such a case, this would have been the **only** network interface to the pod, since Kubernetes just takes the first configuration file from that directory (sorted by alphabetical order) and use it to provide a single interface for all pods.

If we have Multus around, and some other CNI (e.g. flannel), in addition to the bridge one, we could have have defined another `NetworkAttachmentDefinition` object, of type `flannel`, with its configuration, for example:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: flannel-network
spec:
  config: '{
    "cniVersion": "0.3.0",
    "type": "flannel",
    "delegate": {
      "isDefaultGateway": true
    }
  }'
```

Add a reference to it in the pod's annotation, and have two interfaces, connected to two different networks on the pod.

It is quite common that basic networking is provided by one of the mainstream CNIs (flannel, calico, weave etc.) for all pods, and more advanced cases are added specifically when needed. For that, a default CNI could be configured for Multus, so that a `NetworkAttachmentDefinition` object is not needed, nor any annotation at pod level. The interface provided for such a network wil be marked as `eth0` on the pod, for smooth transition when Multus is introduced into an cluster with networking. Any other interface added to the pod due to an explicit `NetworkAttachmentDefinition` object, will be marked as: `net1`, `net2` and so on.

# How Does it Work in KubeVirt?

Most initial steps would be the same as in the pod's case:

- Install the different CNIs that you would like to provide networks to our Virtual Machines
- Install Multus
- Configure Multus with some default CNI that we would like to provide `eth0` for all Virtual Machines
- Add `NetworkAttachmentDefinition` object for each network that we would like some of our Virtual Machines to be using
  Now, inside the VMI (virtual Machine Instance) definition, a new type of `network` called `multus` should be added:

```yaml
 networks:
  - name: default-net
     pod: {}
  - name: another-net
    multus:
      networkName: a-bridge-network
```

This would allow VMI interfaces to be connected to two networks:

- `default` which is connected to the CNI which is defined as the default one for Multus. No `NetworkAttachmentDefinition` CRD is needed for this one, and we assume that the needed configuration is just taken from the default CNI's configuration under `/etc/cni/net.d/`. We also assume that an IP address will be provided to `eth0` on the pod, which will be delegated to the Virtual Machine's `eth0` interface.

- `another-net` which is connected to the network defined by a `NetworkAttachmentDefinition` CRD named `a-bridge-network`. The identity fo the CNI that would actually provide the network, as well as the configuration for this network are all defined in the CRD. An interface named `net1` connected to that network wil be created on the pod. If this interface get an IP address from the CNI, this IP will be delegated to the Virtual Machine's `eth1` interface. If no IP address is given by the CNI, no IP will be given to `eth1` on the Virtual Machine, and only L2 connectivity will be provided.

# Deployment Example

In the following example we use flannel as the CNI that provides the primary pod network, and an [OVS bridge CNI](https://github.com/kubevirt/ovs-cni) provides a secondary network.

## Install Kubernetes

- This was tested with latest version, on a single node cluster. Best would be to just follow [these instructions](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
- Since we use a single node cluster, Don't forget to allow scheduling pods on the master:

```bash
$ kubectl taint nodes --all node-role.kubernetes.io/master-
```

- If running `kubectl` from master itself, don't forget to copy over the conf file:

```bash
$ mkdir -p /$USER/.kube && cp /etc/kubernetes/admin.conf /$USER/.kube/config
```

## Install Flannel

- Make sure pass these parameters are used when starting `kubeadm`:

```bash
$ kubeadm init --pod-network-cidr=10.244.0.0/16
```

- Then call:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
```

## Install and Start OVS

- On Fedora28 that would be (see [here](http://docs.openvswitch.org/en/latest/intro/install/general/) for other options):

```bash
$ dnf install openvswitch
$ systemctl start openvswitch
```

## Install and Configure Multus

- Install Multus as a daemon set (flannel is already set as the default CNI in the yaml below):

```bash
$ kubectl apply -f https://raw.githubusercontent.com/intel/multus-cni/master/images/multus-daemonset.yml
```

- Make sure that Multus is the first CNI under: `/etc/cni/net.d/`. If not, rename it so it would be the first, e.g.: `mv /etc/cni/net.d/70-multus.conf /etc/cni/net.d/00-multus.conf`

## Install and Configure OVS CNI

- First step would be to create the OVS bridge:

```bash
ovs-vsctl add-br blue
```

- To install the OVS CNI use:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubevirt/ovs-cni/master/examples/ovs-cni.yml
```

- Create a `NetworkAttachmentDefinition` CRD for the "blue" bridge:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovs-blue
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "ovs",
    "bridge": "blue"
    }'
```

- To use as specific port/vlan from that bridge, you should first create one:

```bash
ovs-vsctl add-br blue1 blue 100
```

- Then, define its `NetworkAttachmentDefinition` CRD:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovs-blue100
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "ovs",
    "bridge": "blue100",
    "vlan": 100
    }'
```

- More information could be found in the [OVS CNI documentation](https://github.com/kubevirt/ovs-cni/blob/master/docs/deployment-on-arbitrary-cluster.md)

## Deploy a Virtual Machine with 2 Interfaces

- First step would be to deploy KubeVirt (note that 0.8 is needed for Multus support):

```bash
$ export VERSION=v0.8.0
$ kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt.yaml
```

- Now, create a VMI with 2 interfaces, one connected to the default network (flannel in our case) and one to the OVS "blue" bridge:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
  labels:
    special: vmi-multus-multiple-net
  name: vmi-multus-multiple-net
spec:
  domain:
    devices:
      disks:
        - disk:
            bus: virtio
          name: registrydisk
          volumeName: registryvolume
        - disk:
            bus: virtio
          name: cloudinitdisk
          volumeName: cloudinitvolume
      interfaces:
        - bridge: {}
          name: default
        - bridge: {}
          name: ovs-blue-net
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  networks:
    - name: default
      pod: {}
    - multus:
        networkName: ovs-blue
      name: ovs-blue-net
  terminationGracePeriodSeconds: 0
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/fedora-cloud-registry-disk-demo
    - cloudInitNoCloud:
        userData: |
          #!/bin/bash
          echo "fedora" | passwd fedora --stdin
      name: cloudinitvolume
status: {}
```

- Once the machine is up and running, you can use `virtctl` to log into it and make sure that `eth0` exists as the default interface (with an IP address on the flannel subnet) and `eth1` as the interface connected to the OVS bridge (without an IP)
