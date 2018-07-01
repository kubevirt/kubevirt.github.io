---
layout: post
author: phoracek
description: OVN Multi-Network Plugin for Kubernetes, Kubetron
navbar_active: Blogs
pub-date: May 16
pub-year: 2018
category: uncategorized
comments: true
---

Kubernetes networking model is suited for containerized applications, based mostly around L4 and L7 services, where all pods are connected to one big network. This is perfectly ok for most use cases. However, sometimes there is a need for fine-grained network configuration with better control. Use-cases such as L2 networks, static IP addresses, interfaces dedicated for storage traffic etc. For such needs there is ongoing effort in Kubernetes sig-network to support multiple networks (see [Kubernetes Network CRD De-Facto Standard](https://docs.google.com/document/d/1Ny03h6IDVy_e_vmElOqR7UdTPAG_RNydhVE1Kx54kFQ). There exist many prototypes of plugins providing such functionality. You are reading about one of them.

Kubetron (working name, `kubernetes + neutron`, quite misleading since we want to support setup without Neutron involved too), allows users to connect their pods to multiple networks configured on OVN. Important part here is, that such networks are configured by an external tool, be it OVN Northbound Database client or higher level tool such as Neutron or oVirt Provider OVN. This allows administrators to configure complicated networks, Kubernetes then only knows enough about the known networks to be able to connect to them - but not all the complexity involved to manage them. Kubetron does not affect default Kubernetes networking at all, default networks will be left intact.

In order to enable the use-cases outlined above, Kubetron can be used to provide multiple interfaces to a pod, further more KubeVirt will then use those interfaces to pass them to its virtual machines via the in progress [VirtualMachine networking API](https://docs.google.com/document/d/10rXr91aqn8MvVcLgHw33WX8BaQwHPZERp25PHxoZGgw/edit?usp=sharing).

You can find source code in [Kubetron GitHub repository](https://github.com/phoracek/kubetron).

## Contents

* Desired Model and Usage
* Proof of Concept
* Demo
* Try it Yourself
* Looking for Help
* Disclaimer

## Desired Model and Usage

Let's talk about how Kubetron looks from administrator's and user's point of view. Please note that following examples are still for the desired state and some of them might not be implemented in PoC yet. If you want to learn more about deployment and architecture, check [Kubetron slide deck](https://docs.google.com/presentation/d/1KiHQyZngdaL8gtreL9Tmy7S1XiY5Sbnn0YuNCqhggF8/edit?usp=sharing).

### Configure OVN Networks

First of all, administrator must create and configure networks in OVN. That could be done either directly on OVN northbound database (e.g. using `ovn-nbctl`) or via OVN manager (e.g. Neutron or oVirt Provider OVN, using ansible).

### Expose Available Networks

Once the networks are configured, there are two options how to expose available networks to a user. First one is providing some form of access to OVN or Neutron API, this one is completely out of Kubernetes' and Kubetron's
scope. Second option is to enable Network object support (as described in Kubernetes Network CRD De-Facto standard). With this option, administrator must create a Network object per each OVN network is allowed to be used by a user. This object allows administrator to expose only limited subset of networks or to limit access per Namespace. This process could be automated, e.g. via a service that monitors available logical switches and exposes them as Networks.

```shell
# List networks (Logical Switches) directly from OVN Northbound database
ovn-nbctl ls-list

# List networks available on Neutron
neutron net-list

# List networks as Network objects created in Kubernetes
kubectl get networks
```

### Attach pod to a Network

Once user selects a desired network based on options described in previous section, he or she can request them for a pod using an annotation. This annotation is compatible with earlier mentioned Kubernetes Network CRD De-Facto Standard.

```yaml
apiVersion: v1
kind: pod
metadata:
  name: network-consumer
  annotations:
    kubernetes.v1.cni.cncf.io/networks: red  # requested networks
spec:
  containers:
  - name: busybox
    image: busybox
```

### Access the Network from the pod

Once the pod is created, a user can list its interfaces and their assigned IP addresses:

```bash
$ kubectl exec -it network-consumer -- ip address
...
10: red-bcxoeffrsw: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1442 qdisc noqueue state UNKNOWN qlen 1000
    link/ether 4e:71:3b:ee:a5:f4 brd ff:ff:ff:ff:ff:ff
    inet 10.1.0.3/24 brd 10.1.0.255 scope global dynamic red-bcxoeffrsw
       valid_lft 86371sec preferred_lft 86371sec
    inet6 fe80::4c71:3bff:feee:a5f4/64 scope link
       valid_lft forever preferred_lft forever
...
```

In order to make it easier to obtain the network's interface name inside pod's containers, environment variables with network-interface mapping are created:

```bash
$ echo $NETWORK_INTERFACE_RED
red-bcxoeffrsw
```

## Proof of Concept

As for now, current implementation does not completely implement the desired model yet:

* Only Neutron mode is implemented, Kubetron can not be used with OVN alone
* Network object handling is not implemented, Kubetron obtains networks directly from Neutron
* Interface names are not exposed as environment variables

It might be unstable and there are some missing parts. However, basic scenario works, at least in development environment.

## Demo

In the following recording we create two networks `red` and `blue` using Neutron API via Ansible. Then we create two pods and connect them to both mentioned networks. And then we `ping`.

[![asciicast](https://asciinema.org/a/7nB3vgIJcz05TxRNiaD2vLLdE.png)](https://asciinema.org/a/7nB3vgIJcz05TxRNiaD2vLLdE)

## Try it Yourself

I encourage you to try Kubetron yourself. It has not yet been tested on regular Kubernetes deployment (and it likely won't work without some tuning). Fortunately, Kubetron repository contains Vagrant file and set of scripts that will help you deploy multi-node Kubernetes
with OVN and Kubetron installed. On top of that it describes how to create networks and connect pods to them. Check out [Kubetron README.md](https://github.com/phoracek/kubetron/blob/master/README.md) and give it a try!

## Looking for Help

If you are interested in contributing to Kubetron, please follow its GitHub repository. There are many missing features and possible improvements, I will open issues to track them soon. Stay tuned!

## Disclaimer

Kubetron is in early development stage, both it's architecture and tools to use it will change.
