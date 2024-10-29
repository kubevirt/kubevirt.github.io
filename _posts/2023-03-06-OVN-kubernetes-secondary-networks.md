---
layout: post
author: Miguel Duarte Barroso
title: Secondary networks for KubeVirt VMs using OVN-Kubernetes
description: This post explains how to configure cluster-wide overlays as secondary networks for KubeVirt virtual machines.
navbar_active: Blogs
pub-date: March 06
pub-year: 2023
category: news
tags:
  [
    "Kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "SDN",
    "OVN"
  ]
comments: true
---

## Introduction
OVN (Open Virtual Network) is a series of daemons for the Open vSwitch that
translate virtual network configurations into OpenFlow. It provides virtual
networking capabilities for any type of workload on a virtualized platform
(virtual machines and containers) using the same API.

OVN provides a higher-layer of abstraction than Open vSwitch, working with
logical routers and logical switches, rather than flows.
More details can be found in the OVN architecture
[man page](https://man7.org/linux/man-pages/man7/ovn-architecture.7.html#DESCRIPTION).

In this post we will repeat the scenario of
[its bridge CNI equivalent](https://kubevirt.io/2020/Multiple-Network-Attachments-with-bridge-CNI.html),
using this SDN approach, which uses virtual networking infrastructure: thus, it
is **not** required to provision VLANs or other physical network resources.

## Demo
To run this demo, you will need a Kubernetes cluster with the following
components installed:
- OVN-Kubernetes
- multus-cni
- KubeVirt

The [following section](#environment-setup) will show you how to create a
[KinD](https://kind.sigs.k8s.io/) cluster, with upstream latest OVN-Kubernetes,
and upstream latest multus-cni deployed. Please **skip** this section if your
cluster already features these components (e.g. Openshift).

### Setup demo environment
Refer to the OVN-Kubernetes repo
[KIND documentation](https://github.com/ovn-org/ovn-kubernetes/blob/master/docs/kind.md#ovn-kubernetes-kind-setup)
for more details; the gist of it is you should clone the OVN-Kubernetes
repository, and run their kind helper script:

```bash
git clone git@github.com:ovn-org/ovn-kubernetes.git

cd ovn-kubernetes
pushd contrib ; ./kind.sh --multi-network-enable ; popd
```

This will get you a running kind cluster, configured to use OVN-Kubernetes as
the default cluster network, configuring the multi-homing OVN-Kubernetes feature
gate, and deploying
[multus-cni](https://github.com/k8snetworkplumbingwg/multus-cni) in the cluster.

#### Install KubeVirt in the cluster
Follow Kubevirt's
[user guide](https://kubevirt.io/user-guide/operations/installation/#installing-kubevirt-on-kubernetes)
to install the latest released version (currently, v0.59.0). Please skip this
section if you already have a running cluster with KubeVirt installed in it.

```bash
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml"
kubectl -n kubevirt wait kv kubevirt --timeout=360s --for condition=Available
```

Now we have a Kubernetes cluster with all the pieces to start the Demo.

### Define the overlay network
Provision the following yaml to define the overlay which will configure the
secondary attachment for the KubeVirt VMs. Please refer to the OVN-Kubernetes
user
[documentation](https://github.com/ovn-org/ovn-kubernetes/blob/master/docs/multi-homing.md#switched---layer-2---topology)
for details into each of the knobs.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: l2-network
  namespace: default
spec:
  config: |2
    {
            "cniVersion": "0.3.1",
            "name": "l2-network",
            "type": "ovn-k8s-cni-overlay",
            "topology":"layer2",
            "netAttachDefName": "default/l2-network"
    }
EOF
```

The above example will configure a cluster-wide overlay **without** a subnet
defined. This means the users will have to define static IPs for their VMs.

It is also worth to point out the value of the `netAttachDefName` attribute
must match the `<namespace>/<name>` of the surrounding
`NetworkAttachmentDefinition` object.

### Spin up the VMs
```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-server
spec:
  runStrategy: Always
  template:
    spec:
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
          - name: flatl2-overlay
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      - name: flatl2-overlay
        multus:
          networkName: l2-network
      terminationGracePeriodSeconds: 0
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:devel
        - name: cloudinitdisk
          cloudInitNoCloud:
            networkData: |
              version: 2
              ethernets:
                eth1:
                  addresses: [ 192.0.2.20/24 ]
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-client
spec:
  runStrategy: Always
  template:
    spec:
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
          - name: flatl2-overlay
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      - name: flatl2-overlay
        multus:
          networkName: l2-network
      terminationGracePeriodSeconds: 0
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:devel
        - name: cloudinitdisk
          cloudInitNoCloud:
            networkData: |
              version: 2
              ethernets:
                eth1:
                  addresses: [ 192.0.2.10/24 ]
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
EOF
```

Provision these two Virtual Machines, and wait for them to boot up.

### Test connectivity
To verify connectivity over our layer 2 overlay, we need first to ensure the IP
address of the server VM; let's query the VMI status for that:
```bash
kubectl get vmi vm-server -ojsonpath="{ @.status.interfaces }" | jq
[
  {
    "infoSource": "domain, guest-agent",
    "interfaceName": "eth0",
    "ipAddress": "10.244.2.8",
    "ipAddresses": [
      "10.244.2.8"
    ],
    "mac": "52:54:00:23:1c:c2",
    "name": "default",
    "queueCount": 1
  },
  {
    "infoSource": "domain, guest-agent",
    "interfaceName": "eth1",
    "ipAddress": "192.0.2.20",
    "ipAddresses": [
      "192.0.2.20",
      "fe80::7cab:88ff:fe5b:39f"
    ],
    "mac": "7e:ab:88:5b:03:9f",
    "name": "flatl2-overlay",
    "queueCount": 1
  }
]
```

You can afterwards connect to them via console and ping `vm-server`:

> Note "Note"
> The user and password for this VMs is fedora; check the VM template spec cloudinit userData

```bash
virtctl console vm-client
ip a # confirm the IP address is the one set via cloud-init
[fedora@vm-client ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:29:de:53 brd ff:ff:ff:ff:ff:ff
    altname enp1s0
    inet 10.0.2.2/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 86313584sec preferred_lft 86313584sec
    inet6 fe80::5054:ff:fe29:de53/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc fq_codel state UP group default qlen 1000
    link/ether 36:f9:29:65:66:55 brd ff:ff:ff:ff:ff:ff
    altname enp2s0
    inet 192.0.2.10/24 brd 192.0.2.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::34f9:29ff:fe65:6655/64 scope link
       valid_lft forever preferred_lft forever

[fedora@vm-client ~]$ ping -c4 192.0.2.20 # ping the vm-server static IP
PING 192.0.2.20 (192.0.2.20) 56(84) bytes of data.
64 bytes from 192.0.2.20: icmp_seq=1 ttl=64 time=1.05 ms
64 bytes from 192.0.2.20: icmp_seq=2 ttl=64 time=1.05 ms
64 bytes from 192.0.2.20: icmp_seq=3 ttl=64 time=0.995 ms
64 bytes from 192.0.2.20: icmp_seq=4 ttl=64 time=0.902 ms

--- 192.0.2.20 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 0.902/0.997/1.046/0.058 ms
```
## Conclusion
In this post we have seen how to use OVN-Kubernetes to create an overlay to
connect VMs in different nodes using secondary networks, without having to
configure any physical networking infrastructure.

