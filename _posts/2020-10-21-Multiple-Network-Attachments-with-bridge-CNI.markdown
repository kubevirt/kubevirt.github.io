---
layout: post
author: ellorent
title: Multiple Network Attachments with bridge CNI
description: This post illustrates configuring secondary interfaces at VMs with a L2 linux bridge at nodes using just kube api.
navbar_active: Blogs
pub-date: October 21
pub-year: 2020
category: news
tags:
  [
    kubevirt-hyperconverged,
    cnao,
    cluster-network-addons-operator,
    kubernetes-nmstate,
    nmstate,
    bridge,
    multus,
    networking,
    CNI,
    multiple networks,
  ]
comments: true
---

## Introduction

Over the last years the KubeVirt project has improved a lot regarding secondary interfaces networking configuration. Now it's possible to do an end to end configuration from host networking to a VM using just the Kubernetes API with
special Custom Resource Definitions. Moreover, the deployment of all the projects has been simplified by introducing [KubeVirt hyperconverged cluster operator (HCO)](https://github.com/kubevirt/hyperconverged-cluster-operator) and [cluster network addons operator (CNAO)](https://github.com/kubevirt/cluster-network-addons-operator) to install the networking components.

The following is the operator hierarchy list presenting the deployment responsibilities of the HCO and CNAO operators used in this blog post:

- kubevirt-hyperconverged-cluster-operator (HCO)
  - cluster-network-addons-operator (CNAO)
    - multus
    - bridge-cni
    - kubemacpool
    - kubernetes-nmstate
  - KubeVirt

## Introducing cluster-network-addons-operator

The [cluster network addons operator](https://github.com/kubevirt/cluster-network-addons-operator) manages the lifecycle (deploy/update/delete) of different Kubernetes network components needed to
configure secondary interfaces, manage MAC addresses and defines networking on hosts for pods and VMs.

A Good thing about having an operator is that everything is done through the API and you don't have to go over all nodes to install these components yourself and assures smooth updates.

In this blog post we are going to use the following components, explained in a greater detail later on:

- multus: to start a secondary interface on containers in pods
- linux bridge CNI: to use bridge CNI and connect the secondary interfaces from pods to a linux bridge at nodes
- kubemacpool: to manage mac addresses
- kubernetes-nmstate: to configure the linux bridge on the nodes

The list of components we want CNAO to deploy is specified by the `NetworkAddonsConfig` Custom Resource (CR) and the progress of the installation appears in the CR status field, split per component. To inspect
this progress we can query the CR status with the following command:

```bash
kubectl get NetworkAddonsConfig cluster -o yaml
```

To simplify this blog post we are going to use directly the NetworkAddonsConfig from HCO, which by default installs all the network components, but just to illustrate CNAO configuration, the following is a NetworkAddonsConfig CR instructing to deploy multus, linuxBridge, nmstate and kubemacpool components:

```yaml
apiVersion: networkaddonsoperator.network.kubevirt.io/v1
kind: NetworkAddonsConfig
metadata:
  name: cluster
spec:
  multus: {}
  linuxBridge: {}
  nmstate: {}
  imagePullPolicy: Always
```

## Connecting Pods, VMs and Nodes over a single secondary network with bridge CNI

Although Kubernetes provides a default interface that gives connectivity to pods and VMs, it's not easy to configure which NIC should be used for specific pods or VMs in a multi NIC node cluster. A Typical use case is to split control/traffic planes isolated by different NICs on nodes.

With linux bridge CNI + multus it's possible to create a secondary NIC in pod containers and attach it to a L2 linux bridge on nodes. This will add container's connectivity to a specific NIC on nodes if that NIC is part of the L2 linux bridge.

To ensure the configuration is applied only in pods on nodes that have the bridge, the `k8s.v1.cni.cncf.io/resourceName` label is added. This goes hand in hand with another component, [bridge-marker](https://github.com/kubevirt/bridge-marker) which inspects nodes networking and if a new bridge pops up it will mark the node status with it.

This is an example of the results from bridge-marker on nodes where bridge br0 is already configured:

```yaml
---
status:
  allocatable:
    bridge.network.kubevirt.io/br0: 1k
  capacity:
    bridge.network.kubevirt.io/br0: 1k
```

This is an example of `NetworkAttachmentDefinition` to expose the bridge available on the host to users:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: bridge-network
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br0
spec:
  config: >
    {
        "cniVersion": "0.3.1"
        "name": "br0-l2",
        "plugins": [{
            "type": "bridge",
            "bridge": "br0",
            "ipam": {}
        }]
    }
```

Then adding the bridge secondary network to a pod is a matter of adding the following annotation to
it:

```yaml
annotations:
  k8s.v1.cni.cncf.io/networks: br0-l2
```

## Setting up node networking with NodeNetworkConfigurationPolicy (aka nncp)

Changing Kubernetes cluster node networking can be done manually iterating over all the cluster nodes and making changes or using different automatization tools like ansible. However, using just another Kubernetes resource is more convenient.
For this purpose the kubernetes-nmstate project was born as a cluster wide node network administrator based on Kubernetes CRs on top of [nmstate](https://github.com/nmstate/nmstate).

It works as a Kubernetes `DaemonSet` running pods on all the cluster nodes and reconciling three different CRs:

- [NodeNetworkConfigurationPolicy](https://raw.githubusercontent.com/nmstate/kubernetes-nmstate/master/deploy/crds/nmstate.io_v1beta1_nodenetworkconfigurationpolicy_cr.yaml) to specify cluster node network desired configuration
- [NodeNetworkConfigurationEnactment](https://raw.githubusercontent.com/nmstate/kubernetes-nmstate/master/deploy/crds/nmstate.io_v1beta1_nodenetworkconfigurationenactment_cr.yaml) (nnce) to troubleshoot issues with nncp
- [NodeNetworkState](https://raw.githubusercontent.com/nmstate/kubernetes-nmstate/master/deploy/crds/nmstate.io_v1beta1_nodenetworkstate_cr.yaml) (nns) to view the node's networking configuration

> note "Note"
> Project kubernetes-nmstate has a distributed architecture to reduce kube-apiserver connectivity dependency, this means that every pod will configure the networking on the node that it's running without much interaction with kube-apiserver.

In case something goes wrong and the pod changing the node network cannot ping the default gateway, resolve DNS root servers or has lost the kube-apiserver connectivity it will rollback to the previous configuration to go back to a working state. Those errors can be checked by running `kubectl get nnce`. The command displays potential issues per node and nncp.

The desired state fields follow the nmstate API described at their [awesome doc](https://www.nmstate.io/)

Also for more details on kubernetes-nmstate there are guides covering [reporting](https://github.com/nmstate/kubernetes-nmstate/blob/master/docs/user-guide/101-reporting.md), [configuration](https://github.com/nmstate/kubernetes-nmstate/blob/master/docs/user-guide/102-configuration.md) and [troubleshooting](https://github.com/nmstate/kubernetes-nmstate/blob/master/docs/user-guide/103-troubleshooting.md). There are also [nncp examples](https://github.com/nmstate/kubernetes-nmstate/tree/master/docs/examples).

## Demo: mixing it all together, VM to VM communication between nodes

With the following recipe we will end up with a pair of virtual machines pair on two different nodes with one secondary NICs, eth1 at vlan 100. They will be connected to each other using
the same bridge on nodes that also have the external secondary NIC eth1 connected.

### Demo environment setup

We are going to use a [kubevirtci](https://github.com/kubevirt/kubevirtci) as Kubernetes ephemeral cluster provider.

To start it up with two nodes and one secondary NIC and install NetworkManager >= 1.22 (needed for kubernetes-nmstate) and dnsmasq follow these steps:

```bash
git clone https://github.com/kubevirt/kubevirtci
cd kubevirtci
# Pin to version working with blog post steps in case
# k8s-1.19 provider disappear in the future
git reset d5d8e3e376b4c3b45824fbfe320b4c5175b37171 --hard
export KUBEVIRT_PROVIDER=k8s-1.19
export KUBEVIRT_NUM_NODES=2
export KUBEVIRT_NUM_SECONDARY_NICS=1
make cluster-up
export KUBECONFIG=$(./cluster-up/kubeconfig.sh)
```

### Installing components

To install KubeVirt we are going to use the operator [kubevirt-hyper-converged-operator](https://github.com/kubevirt/hyperconverged-cluster-operator), this will install all the components
needed to have a functional KubeVirt with all the features including the ones we are going to use: multus, linux-bridge, kubemacpool and kubernetes-nmstate.

```bash
curl https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/master/deploy/deploy.sh | bash
kubectl wait hco -n kubevirt-hyperconverged kubevirt-hyperconverged --for condition=Available --timeout=500s
```

Now we have a Kubernetes cluster with all the pieces to startup a VM with bridge attached to a secondary NIC.

### Creating the br0 on nodes with a port attached to secondary NIC eth1

First step is to create a L2 linux-bridge at nodes with one port on the secondary NIC eth1, this will be
used later on by the bridge CNI.

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: nmstate.io/v1alpha1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br0-eth1
spec:
  desiredState:
    interfaces:
    - name: br0
      description: Linux bridge with eth1 as a port
      type: linux-bridge
      state: up
      bridge:
        options:
          stp:
            enabled: false
        port:
        - name: eth1
EOF
```

Now we wait for the bridge to be created checking nncp conditions:

```bash
kubectl wait nncp br0-eth1 --for condition=Available --timeout 2m
```

After the nncp becomes available, we can query the nncp resources in the cluster
and see it listed with successful status.

```bash
kubectl get nncp
```

```bash
NAME       STATUS
br0-eth1   SuccessfullyConfigured
```

We can inspect the status of applying the policy to each node.
For that there is the `NodeNetworkConfigurationEnactment` CR (nnce):

```bash
kubectl get nnce
```

```bash
NAME              STATUS
node01.br0-eth1   SuccessfullyConfigured
node02.br0-eth1   SuccessfullyConfigured
```

> note "Note"
> In case of errors it is possible to retrieve the error dumped by nmstate running
> `kubectl get nnce -o yaml` the status will contain the error.

We can also inspect the network state on the nodes by retrieving the `NodeNetworkState` and
checking if the bridge `br0` is up using jsonpath

```bash
kubectl get nns node01 -o=jsonpath='{.status.currentState.interfaces[?(@.name=="br0")].state}'
kubectl get nns node02 -o=jsonpath='{.status.currentState.interfaces[?(@.name=="br0")].state}'
```

When inspecting the full currentState yaml we get the following
interface configuration:

```bash
kubectl get nns node01 -o yaml
```

```yaml
status:
  currentState:
    interfaces:
      - bridge:
          options:
            group-forward-mask: 0
            mac-ageing-time: 300
            multicast-snooping: true
            stp:
              enabled: false
              forward-delay: 15
              hello-time: 2
              max-age: 20
              priority: 32768
          port:
            - name: eth1
              stp-hairpin-mode: false
              stp-path-cost: 100
              stp-priority: 32
        description: Linux bridge with eth1 as a port
        ipv4:
          dhcp: false
          enabled: false
        ipv6:
          autoconf: false
          dhcp: false
          enabled: false
        mac-address: 52:55:00:D1:56:00
        mtu: 1500
        name: br0
        state: up
        type: linux-bridge
```

We can also check that the `bridge-marker` is working and check verify on nodes:

```bash
kubectl get node node01 -o yaml
```

The following should appear stating that br0
can be consumed on the node:

```yaml
status:
  allocatable:
    bridge.network.kubevirt.io/br0: 1k
  capacity:
    bridge.network.kubevirt.io/br0: 1k
```

At this point we have an L2 linux bridge ready and connected to NIC eth1.

### Configure network attachment with a L2 bridge and a vlan

In order to make the bridge a L2 bridge, we specify no IPAM (IP Address Management) since we are
not going to configure any ip address for the bridge. To configure
bridge vlan-filtering we add the vlan we want to use to isolate our VMs:

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: br0-100-l2
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br0
spec:
  config: >
    {
        "cniVersion": "0.3.1",
        "name": "br0-100-l2-config",
        "plugins": [
            {
                "type": "bridge",
                "bridge": "br0",
                "vlan": 100,
                "ipam": {}
            },
            {
                "type": "tuning"
            }
        ]
    }
EOF
```

### Start a pair of VMs on different nodes using the multus configuration to connect a secondary interfaces to br0

Now it's time to startup the VMs running on different nodes so we can check external connectivity of
br0. They will also have a secondary NIC eth1 to connect to the other VM running at different node, so they go
over the br0 at nodes.

The following picture illustrates the cluster:

<!-- yaspeller ignore:start -->

{% svg /assets/images/kubevirt-linux-bridge-vm-to-vm.svg %}

<!-- NOTE: When gnudot is at production use proper liquid tags to use this code -->
<!--
graph bridge {
node [shape=square, style=filled color=gold];
splines=line;
subgraph cluster_kubevirtci {
label = "kubevirtci cluster";
color = mediumseagreen;
style = filled;
nd_br1_kubevirtci [label = "br1"]
subgraph cluster_node01 {
label = "node01";
color = khaki4;
style=filled;
nd_br0_node01 [label = "br0"]
nd_eth1_node01 [label = "eth1"]
subgraph cluster_vma {
label = "vma";
style=filled;
color=lightcyan3;
nd_eth1_vma [label = "eth1"];
}

    }
    subgraph cluster_node02 {
      label = "node02";
      color = khaki4;
      style = filled;
      nd_br0_node02 [label = "br0"]
      nd_eth1_node02 [label = "eth1"]
      subgraph cluster_vmb {
        label = "vmb";
        style=filled;
        color=lightcyan3;
        nd_eth1_vmb [label = "eth1"];
      }

    }
    nd_eth1_node01 -- nd_br1_kubevirtci
    nd_eth1_node02 -- nd_br1_kubevirtci
    nd_br0_node01 -- nd_eth1_node01
    nd_br0_node01 -- nd_eth1_vma
    nd_br0_node02 -- nd_eth1_node02
    nd_br0_node02 -- nd_eth1_vmb

}
}
-->

<!-- yaspeller ignore:end -->

First step is to install the `virtctl` command line tool to play with virtual machines:

```bash
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/v0.33.0/virtctl-v0.33.0-linux-amd64
chmod +x virtctl
sudo install virtctl /usr/local/bin
```

Now let's create two `VirtualMachine`s on each node. They will have one secondary NIC connected to br0 using the multus configuration for vlan 100. We will also activate kubemacpool to be sure that mac addresses are unique in the cluster and install the qemu-guest-agent so IP addresses from secondary NICs are reported to VM and we can inspect them later on.

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: default
  labels:
    mutatevirtualmachines.kubemacpool.io: allocate
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vma
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: node01
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          interfaces:
          - name: default
            masquerade: {}
          - name: br0-100
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      - name: br0-100
        multus:
          networkName: br0-100-l2
      terminationGracePeriodSeconds: 0
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/fedora-cloud-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            networkData: |
              version: 2
              ethernets:
                eth1:
                  addresses: [ 10.200.0.1/24 ]
            userData: |-
              #!/bin/bash
              echo "fedora" |passwd fedora --stdin
              dnf -y install qemu-guest-agent
              sudo systemctl enable qemu-guest-agent
              sudo systemctl start qemu-guest-agent
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vmb
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: node02
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          interfaces:
          - name: default
            masquerade: {}
          - name: br0-100
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      - name: br0-100
        multus:
          networkName: br0-100-l2
      terminationGracePeriodSeconds: 0
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/fedora-cloud-container-disk-demo
        - name: cloudinitdisk
          cloudInitNoCloud:
            networkData: |
              version: 2
              ethernets:
                eth1:
                  addresses: [ 10.200.0.2/24 ]
            userData: |-
              #!/bin/bash
              echo "fedora" |passwd fedora --stdin
              dnf -y install qemu-guest-agent
              sudo systemctl enable qemu-guest-agent
              sudo systemctl start qemu-guest-agent
EOF
```

Wait for the two VMs to be ready.
Eventually you will see something like this:

```bash
kubectl get vmi
```

```bash
NAME      AGE    PHASE     IP               NODENAME
vma      2m4s   Running   10.244.196.142   node01
vmb      2m4s   Running   10.244.140.86    node02
```

We can check that they have one secondary NIC without
address assigned:

```bash
kubectl get vmi -o yaml
```

```yaml
## vma
  interfaces:
  - interfaceName: eth0
    ipAddress: 10.244.196.144
    ipAddresses:
    - 10.244.196.144
    - fd10:244::c48f
    mac: 02:4a:be:00:00:0a
    name: default
  - interfaceName: eth1
    ipAddress: 10.200.0.1/24
    ipAddresses:
    - 10.200.0.1/24
    - fe80::4a:beff:fe00:b/64
    mac: 02:4a:be:00:00:0b
    name: br0-100
## vmb
  interfaces:
  - interfaceName: eth0
    ipAddress: 10.244.140.84
    ipAddresses:
    - 10.244.140.84
    - fd10:244::8c53
    mac: 02:4a:be:00:00:0e
    name: default
  - interfaceName: eth1
    ipAddress: 10.200.0.2/24
    ipAddresses:
    - 10.200.0.2/24
    - fe80::4a:beff:fe00:f/64
    mac: 02:4a:be:00:00:0f
    name: br0-100
```

Let's finish this section by verifying connectivity between vma and vmb using `ping`. Open the console of vma virtual machine and use `ping` command with destination IP address 10.200.0.2, which is the address assigned to the secondary interface of vmb:

> note "Note"
> The user and password for this VMs is `fedora`, it was configured at cloudinit userData

```bash
virtctl console vma
ping 10.200.0.2 -c 3
```

```bash
PING 10.200.0.2 (10.200.0.2): 56 data bytes
64 bytes from 10.200.0.2: seq=0 ttl=50 time=357.040 ms
64 bytes from 10.200.0.2: seq=1 ttl=50 time=379.742 ms
64 bytes from 10.200.0.2: seq=2 ttl=50 time=404.066 ms

--- 10.200.0.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 357.040/380.282/404.066 ms
```

## Conclusion

In this blog post we used network components from KubeVirt project to connect two VMs on different nodes
through a linux bridge connected to a secondary NIC. This illustrates how VM traffic can be directed to a specific NIC
on a node using a secondary NIC on a VM.
