---
layout: post
author: Miguel Duarte Barroso
title: NetworkPolicies for KubeVirt VMs secondary networks using OVN-Kubernetes
description: This post explains how to configure NetworkPolicies for KubeVirt VMs secondary networks.
navbar_active: Blogs
pub-date: July 21
pub-year: 2023
category: news
tags:
  [
    "Kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "SDN",
    "OVN",
    "NetworkPolicy"
  ]
comments: true
---

## Introduction
Kubernetes [NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) are constructs to control traffic flow at the IP
address or port level (OSI layers 3 or 4).
They allow the user to specify how a pod (or group of pods) is allowed to
communicate with other entities on the network. In simpler words: the user can
specify ingress from or egress to other workloads, using L3 / L4 semantics.

Keeping in mind `NetworkPolicy` is a Kubernetes construct - which only cares
about a single network interface - they are only usable for the cluster's
default network interface. This leaves a considerable gap for Virtual Machine
users, since they are heavily invested in secondary networks.

The [k8snetworkplumbingwg](https://github.com/k8snetworkplumbingwg) has addressed this limitation by providing a
`MultiNetworkPolicy` CRD - it features the exact same API as `NetworkPolicy`
but can target [network-attachment-definitions](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/how-to-use.md#create-network-attachment-definition).
[OVN-Kubernetes](https://github.com/ovn-org/ovn-kubernetes) implements this API, and configures access control accordingly
for secondary networks in the cluster.

In this post we will see how we can govern access control for VMs using the
multi-network policy API. On our simple example, we'll only allow into our VMs
for traffic ingressing from a particular CIDR range.

## Current limitations of `MultiNetworkPolicies` for VMs
Kubernetes `NetworkPolicy` has three types of policy peers:
- namespace selectors: allows ingress-from, egress-to based on the peer's namespace labels
- pod selectors: allows ingress-from, egress-to based on the peer's labels
- ip block: allows ingress-from, egress-to based on the peer's IP address

While `MultiNetworkPolicy` allows these three types, when used with VMs we
recommend using **only** the `IPBlock` policy peer - both `namespace` and `pod`
selectors prevent the live-migration of Virtual Machines (these policy peers
require OVN-K managed IPAM, and currently the live-migration feature is only
available when IPAM is not enabled on the interfaces).

## Demo
To run this demo, we will prepare a Kubernetes cluster with the following
components installed:
- [OVN-Kubernetes](https://github.com/ovn-org/ovn-kubernetes)
- [multus-cni](https://github.com/k8snetworkplumbingwg/multus-cni)
- [KubeVirt](https://github.com/kubevirt/kubevirt)
- [Multi-Network policy API](https://github.com/k8snetworkplumbingwg/multi-networkpolicy)

The [following section](#setup-demo-environment) will show you how to create a
[KinD](https://kind.sigs.k8s.io/) cluster, with upstream latest OVN-Kubernetes,
upstream latest multus-cni, and the multi-network policy CRDs deployed.

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

This will get you a running kind cluster (one control plane, and two worker
nodes), configured to use OVN-Kubernetes as the default cluster network,
configuring the multi-homing OVN-Kubernetes feature gate, and deploying
`multus-cni` in the cluster.

### Install KubeVirt in the cluster
Follow Kubevirt's
[user guide](https://kubevirt.io/user-guide/operations/installation/#installing-kubevirt-on-kubernetes)
to install the latest released version (currently, v1.0.0).

```bash
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml"
kubectl -n kubevirt wait kv kubevirt --timeout=360s --for condition=Available
```

Now we have a Kubernetes cluster with all the pieces to start the Demo.

### Limiting ingress to a KubeVirt VM
In this example, we will configure a `MultiNetworkPolicy` allowing ingress into
our VMs only from a particular CIDR range - let's say `10.200.0.0/30`.

Provision the following NAD (to allow our VMs to live-migrate, we do not define
a `subnet`):
```yaml
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: flatl2net
spec:
  config: |2
    {
            "cniVersion": "0.4.0",
            "name": "flatl2net",
            "type": "ovn-k8s-cni-overlay",
            "topology":"layer2",
            "netAttachDefName": "default/flatl2net"
    }
```

Let's now provision our six VMs, with the following name to IP address
(statically configured via cloud-init) association:
- vm1: 10.200.0.1
- vm2: 10.200.0.2
- vm3: 10.200.0.3
- vm4: 10.200.0.4
- vm5: 10.200.0.5
- vm6: 10.200.0.6

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm1
  name: vm1
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        name: access-control
        kubevirt.io/domain: vm1
        kubevirt.io/vm: vm1
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
          interfaces:
          - bridge: {}
            name: flatl2-overlay
          rng: {}
        resources:
          requests:
            memory: 1024Mi
      networks:
      - multus:
          networkName: flatl2net
        name: flatl2-overlay
      termination/GracePeriodSeconds: 30
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.0.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            ethernets:
              eth0:
                addresses:
                - 10.200.0.1/24
            version: 2
          userData: |-
            #cloud-config
            user: fedora
            password: password
            chpasswd: { expire: False }
        name: cloudinitdisk
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm2
  name: vm2
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        name: access-control
        kubevirt.io/domain: vm2
        kubevirt.io/vm: vm2
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
          interfaces:
          - bridge: {}
            name: flatl2-overlay
          rng: {}
        resources:
          requests:
            memory: 1024Mi
      networks:
      - multus:
          networkName: flatl2net
        name: flatl2-overlay
      termination/GracePeriodSeconds: 30
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.0.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            ethernets:
              eth0:
                addresses:
                - 10.200.0.2/24
            version: 2
          userData: |-
            #cloud-config
            user: fedora
            password: password
            chpasswd: { expire: False }
        name: cloudinitdisk
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm3
  name: vm3
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        name: access-control
        kubevirt.io/domain: vm3
        kubevirt.io/vm: vm3
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
          interfaces:
          - bridge: {}
            name: flatl2-overlay
          rng: {}
        resources:
          requests:
            memory: 1024Mi
      networks:
      - multus:
          networkName: flatl2net
        name: flatl2-overlay
      termination/GracePeriodSeconds: 30
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.0.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            ethernets:
              eth0:
                addresses:
                - 10.200.0.3/24
            version: 2
          userData: |-
            #cloud-config
            user: fedora
            password: password
            chpasswd: { expire: False }
        name: cloudinitdisk
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm4
  name: vm4
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        name: access-control
        kubevirt.io/domain: vm4
        kubevirt.io/vm: vm4
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
          interfaces:
          - bridge: {}
            name: flatl2-overlay
          rng: {}
        resources:
          requests:
            memory: 1024Mi
      networks:
      - multus:
          networkName: flatl2net
        name: flatl2-overlay
      termination/GracePeriodSeconds: 30
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.0.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            ethernets:
              eth0:
                addresses:
                - 10.200.0.4/24
            version: 2
          userData: |-
            #cloud-config
            user: fedora
            password: password
            chpasswd: { expire: False }
        name: cloudinitdisk
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm5
  name: vm5
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        name: access-control
        kubevirt.io/domain: vm5
        kubevirt.io/vm: vm5
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
          interfaces:
          - bridge: {}
            name: flatl2-overlay
          rng: {}
        resources:
          requests:
            memory: 1024Mi
      networks:
      - multus:
          networkName: flatl2net
        name: flatl2-overlay
      termination/GracePeriodSeconds: 30
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.0.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            ethernets:
              eth0:
                addresses:
                - 10.200.0.5/24
            version: 2
          userData: |-
            #cloud-config
            user: fedora
            password: password
            chpasswd: { expire: False }
        name: cloudinitdisk
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm6
  name: vm6
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        name: access-control
        kubevirt.io/domain: vm6
        kubevirt.io/vm: vm6
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
          interfaces:
          - bridge: {}
            name: flatl2-overlay
          rng: {}
        resources:
          requests:
            memory: 1024Mi
      networks:
      - multus:
          networkName: flatl2net
        name: flatl2-overlay
      termination/GracePeriodSeconds: 30
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.0.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            ethernets:
              eth0:
                addresses:
                - 10.200.0.6/24
            version: 2
          userData: |-
            #cloud-config
            user: fedora
            password: password
            chpasswd: { expire: False }
        name: cloudinitdisk
```
**NOTE:** it is important to highlight all the Virtual Machines (and the
`network-attachment-definition`) are defined in the `default` namespace.

After this step, we should have the following deployment:

![image](/assets/2023-07-10-OVN-kubernetes-secondary-networks-policies/01-vms-provisioned.png)

Let's check the VMs `vm1` and `vm4` can ping their peers in the same subnet.
For that we will
[connect to the VMs over their serial console](https://kubevirt.io/user-guide/virtual_machines/accessing_virtual_machines/#accessing-the-serial-console):

First, let's check `vm1`:

```bash
➜  virtctl console vm1
Successfully connected to vm1 console. The escape sequence is ^]

[fedora@vm1 ~]$ ping 10.200.0.2 -c 4
PING 10.200.0.2 (10.200.0.2) 56(84) bytes of data.
64 bytes from 10.200.0.2: icmp_seq=1 ttl=64 time=5.16 ms
64 bytes from 10.200.0.2: icmp_seq=2 ttl=64 time=1.41 ms
64 bytes from 10.200.0.2: icmp_seq=3 ttl=64 time=34.2 ms
64 bytes from 10.200.0.2: icmp_seq=4 ttl=64 time=2.56 ms

--- 10.200.0.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 1.406/10.841/34.239/13.577 ms
[fedora@vm1 ~]$ ping 10.200.0.6 -c 4
PING 10.200.0.6 (10.200.0.6) 56(84) bytes of data.
64 bytes from 10.200.0.6: icmp_seq=1 ttl=64 time=3.77 ms
64 bytes from 10.200.0.6: icmp_seq=2 ttl=64 time=1.46 ms
64 bytes from 10.200.0.6: icmp_seq=3 ttl=64 time=5.47 ms
64 bytes from 10.200.0.6: icmp_seq=4 ttl=64 time=1.74 ms

--- 10.200.0.6 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3007ms
rtt min/avg/max/mdev = 1.459/3.109/5.469/1.627 ms
[fedora@vm1 ~]$ 
```

And from vm4:
```bash
➜  ~ virtctl console vm4
Successfully connected to vm4 console. The escape sequence is ^]

[fedora@vm4 ~]$ ping 10.200.0.1 -c 4
PING 10.200.0.1 (10.200.0.1) 56(84) bytes of data.
64 bytes from 10.200.0.1: icmp_seq=1 ttl=64 time=3.20 ms
64 bytes from 10.200.0.1: icmp_seq=2 ttl=64 time=1.62 ms
64 bytes from 10.200.0.1: icmp_seq=3 ttl=64 time=1.44 ms
64 bytes from 10.200.0.1: icmp_seq=4 ttl=64 time=0.951 ms

--- 10.200.0.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 0.951/1.803/3.201/0.843 ms
[fedora@vm4 ~]$ ping 10.200.0.6 -c 4
PING 10.200.0.6 (10.200.0.6) 56(84) bytes of data.
64 bytes from 10.200.0.6: icmp_seq=1 ttl=64 time=1.85 ms
64 bytes from 10.200.0.6: icmp_seq=2 ttl=64 time=1.02 ms
64 bytes from 10.200.0.6: icmp_seq=3 ttl=64 time=1.27 ms
64 bytes from 10.200.0.6: icmp_seq=4 ttl=64 time=0.970 ms

--- 10.200.0.6 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 0.970/1.275/1.850/0.350 ms
```

We will now provision a `MultiNetworkPolicy` applying to all the VMs defined
above. To do this mapping correcly, the policy has to:
- Be in the same namespace as the VM.
- Set `k8s.v1.cni.cncf.io/policy-for` annotation matching the secondary 
  network used by the VM.
- Set `matchLabels` selector matching the labels set on VM's
  `spec.template.metadata`.

This policy will allow ingress into these `access-control` labeled pods 
**only if** the traffic originates from within the `10.200.0.0/30` CIDR range
(IPs 10.200.0.1-3).

```bash
---
apiVersion: k8s.cni.cncf.io/v1beta1
kind: MultiNetworkPolicy
metadata:
  name:  ingress-ipblock
  annotations:
    k8s.v1.cni.cncf.io/policy-for: default/flatl2net
spec:
  podSelector:
    matchLabels:
        name: access-control
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.200.0.0/30
```

 Taking into account our example, only
`vm1`, `vm2`, and `vm3` will be able to contact any of its peers, as pictured
by the following diagram:

![MultiNetworkPolicy is provisioned](/assets/2023-07-10-OVN-kubernetes-secondary-networks-policies/02-no-access.png)

Let's try again the ping after provisioning the `MultiNetworkPolicy` object:

From `vm1` (inside the allowed ip block range):
```bash
[fedora@vm1 ~]$ ping 10.200.0.2 -c 4
PING 10.200.0.2 (10.200.0.2) 56(84) bytes of data.
64 bytes from 10.200.0.2: icmp_seq=1 ttl=64 time=6.48 ms
64 bytes from 10.200.0.2: icmp_seq=2 ttl=64 time=4.40 ms
64 bytes from 10.200.0.2: icmp_seq=3 ttl=64 time=1.28 ms
64 bytes from 10.200.0.2: icmp_seq=4 ttl=64 time=1.51 ms

--- 10.200.0.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 1.283/3.418/6.483/2.154 ms
[fedora@vm1 ~]$ ping 10.200.0.6 -c 4
PING 10.200.0.6 (10.200.0.6) 56(84) bytes of data.
64 bytes from 10.200.0.6: icmp_seq=1 ttl=64 time=3.81 ms
64 bytes from 10.200.0.6: icmp_seq=2 ttl=64 time=2.67 ms
64 bytes from 10.200.0.6: icmp_seq=3 ttl=64 time=1.68 ms
64 bytes from 10.200.0.6: icmp_seq=4 ttl=64 time=1.63 ms

--- 10.200.0.6 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 1.630/2.446/3.808/0.888 ms
```

From `vm4` (**outside** the allowed ip block range):
```bash
[fedora@vm4 ~]$ ping 10.200.0.1 -c 4
PING 10.200.0.1 (10.200.0.1) 56(84) bytes of data.

--- 10.200.0.1 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 3083ms

[fedora@vm4 ~]$ ping 10.200.0.6 -c 4
PING 10.200.0.6 (10.200.0.6) 56(84) bytes of data.

--- 10.200.0.6 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 3089ms
```

## Conclusions
In this post we've shown how `MultiNetworkPolicies` can be used to provide
access control to VMs with secondary network interfaces.

We have provided a comprehensive example on how a policy can be used to limit
ingress to our VMs only from desired sources, based on the client's IP address.
