---
layout: post
author: Miguel Duarte Barroso
title: Secondary networks connected to the physical underlay for KubeVirt VMs using OVN-Kubernetes
description: This post explains how to configure secondary networks connected to the physical underlay for KubeVirt virtual machines.
navbar_active: Blogs
pub-date: May 31
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
using this SDN approach. This secondary network topology is akin to the one
described in the [flatL2 topology](http://kubevirt.io/2023/OVN-kubernetes-secondary-networks.html),
but allows connectivity to the physical underlay.

## Demo
To run this demo, we will prepare a Kubernetes cluster with the following
components installed:
- [OVN-Kubernetes](https://github.com/ovn-org/ovn-kubernetes)
- [multus-cni](https://github.com/k8snetworkplumbingwg/multus-cni)
- [KubeVirt](https://github.com/kubevirt/kubevirt)

The [following section](#environment-setup) will show you how to create a
[KinD](https://kind.sigs.k8s.io/) cluster, with upstream latest OVN-Kubernetes,
and upstream latest multus-cni deployed.

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

### Install KubeVirt in the cluster
Follow Kubevirt's
[user guide](https://kubevirt.io/user-guide/operations/installation/#installing-kubevirt-on-kubernetes)
to install the latest released version (currently, v0.59.0).

```bash
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml"
kubectl -n kubevirt wait kv kubevirt --timeout=360s --for condition=Available
```

Now we have a Kubernetes cluster with all the pieces to start the Demo.

### Single broadcast domain
In this scenario we will see how traffic from a single localnet network can be
connected to a physical network in the host using a dedicated bridge.

This scenario does not use any VLAN encapsulation, thus is simpler, since the
network admin does not need to provision any VLANs in advance.

#### Configuring the underlay
When you've started the KinD cluster with the `--multi-network-enable` flag an
additional OCI network was created, and attached to each of the KinD nodes.

But still, further steps may be required, depending on the desired L2
configuration.

Let's first create a dedicated OVS bridge, and attach the aforementioned
virtualized network to it:
```bash
for node in $(kubectl -n ovn-kubernetes get pods -l app=ovs-node -o jsonpath="{.items[*].metadata.name}")
do
	kubectl -n ovn-kubernetes exec -ti $node -- ovs-vsctl --may-exist add-br ovsbr1
	kubectl -n ovn-kubernetes exec -ti $node -- ovs-vsctl --may-exist add-port ovsbr1 eth1
	kubectl -n ovn-kubernetes exec -ti $node -- ovs-vsctl set open . external_ids:ovn-bridge-mappings=physnet:breth0,localnet-network:ovsbr1
done
```

The first two commands are self-evident: you create an OVS bridge, and attach
a port to it; the last one is not. In it, we're using the
[OVN bridge mapping](https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.0/html/networking_guide/bridge-mappings)
API to configure which OVS bridge must be used for each physical network.
It creates a patch port between the OVN integration bridge - `br-int` - and the
OVS bridge you tell it to, and traffic will be forwarded to/from it with the
help of a
[localnet port](https://man7.org/linux/man-pages/man5/ovn-nb.5.html#Logical_Switch_Port_TABLE).

**NOTE:** The provided mapping **must** match the `name` within the
`net-attach-def`.Spec.Config JSON, otherwise, the patch ports will not be
created.

You will also have to configure an IP address on the bridge for the
extra-network the kind script created. For that, you first need to identify the
bridge's name:
```bash
OCI_BIN=podman | docker # choose your cup of tea.
$OCI_BIN network inspect underlay --format '{ .NetworkInterface }}'
podman3

ip addr add 10.128.0.1/24 dev podman3
```

Let's also use an IP in the same subnet as the network subnet (defined in the
NAD). This IP address must be excluded from the IPAM pool (also on the NAD),
otherwise the OVN-Kubernetes IPAM may assign it to a workload.

#### Defining the OVN-Kubernetes networks
Once the underlay is configured, we can now provision the attachment configuration:
```yaml
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: localnet-network
spec:
  config: |2
    {
            "cniVersion": "0.3.1",
            "name": "localnet-network",
            "type": "ovn-k8s-cni-overlay",
            "topology": "localnet",
            "subnets": "10.128.0.0/24",
            "excludeSubnets": "10.128.0.1/32",
            "netAttachDefName": "default/localnet-network"
    }
```

It is required to list the gateway IP in the `excludedSubnets` attribute, thus
preventing OVN-Kubernetes from assigning that IP address to the workloads.

#### Spin up the VMs
These four VMs (two VMs connected to each tenant network) can be used for the
single broadcast domain scenario (no VLANs).
```yaml
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-server
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: ovn-worker
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
          - name: localnet
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: localnet
        multus:
          networkName: localnet-network
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
                eth0:
                  dhcp4: true
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
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: ovn-worker2
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
          - name: localnet
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: localnet
        multus:
          networkName: localnet-network
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
                eth0:
                  dhcp4: true
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
```

#### Test East / West communication
You can check east/west connectivity between both **red** VMs via ICMP:
```bash
$ kubectl get vmi vm-server -ojsonpath="{ @.status.interfaces }" | jq
[
  {
    "infoSource": "domain, guest-agent",
    "interfaceName": "eth0",
    "ipAddress": "10.128.0.2",
    "ipAddresses": [
      "10.128.0.2",
      "fe80::e83d:16ff:fe76:c1bd"
    ],
    "mac": "ea:3d:16:76:c1:bd",
    "name": "localnet",
    "queueCount": 1
  }
]

$ virtctl console vm-client
Successfully connected to vm-client console. The escape sequence is ^]

[fedora@vm-client ~]$ ping 192.168.123.20
PING 192.168.123.20 (192.168.123.20) 56(84) bytes of data.
64 bytes from 192.168.123.20: icmp_seq=1 ttl=64 time=0.534 ms
64 bytes from 192.168.123.20: icmp_seq=2 ttl=64 time=0.246 ms
64 bytes from 192.168.123.20: icmp_seq=3 ttl=64 time=0.178 ms
64 bytes from 192.168.123.20: icmp_seq=4 ttl=64 time=0.236 ms

--- 192.168.123.20 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3028ms
rtt min/avg/max/mdev = 0.178/0.298/0.534/0.138 ms
```

#### Check underlay services
We can now start HTTP servers listening to the IPs attached on
the gateway:
```bash
python3 -m http.server --bind 10.128.0.1 9000
```

And finally curl this from your client:
```bash
[fedora@vm-client ~]$ curl -v 10.128.0.1:9000
*   Trying 10.128.0.1:9000...
* Connected to 10.128.0.1 (10.128.0.1) port 9000 (#0)
> GET / HTTP/1.1
> Host: 10.128.0.1:9000
> User-Agent: curl/7.69.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
* HTTP 1.0, assume close after body
< HTTP/1.0 200 OK
< Server: SimpleHTTP/0.6 Python/3.11.3
< Date: Thu, 01 Jun 2023 16:05:09 GMT
< Content-type: text/html; charset=utf-8
< Content-Length: 2923
...
```

### Multiple physical networks pointing to the same OVS bridge
This example will feature 2 physical networks, each with a different VLAN,
both pointing at the same OVS bridge.

#### Configuring the underlay
Again, the first thing to do is create a dedicated OVS bridge, and attach the
aforementioned virtualized network to it, while defining it as a trunk port
for two broadcast domains, with tags 10 and 20.
```bash
for node in $(kubectl -n ovn-kubernetes get pods -l app=ovs-node -o jsonpath="{.items[*].metadata.name}")
do
	kubectl -n ovn-kubernetes exec -ti $node -- ovs-vsctl --may-exist add-br ovsbr1
	kubectl -n ovn-kubernetes exec -ti $node -- ovs-vsctl --may-exist add-port ovsbr1 eth1 trunks=10,20 vlan_mode=trunk
	kubectl -n ovn-kubernetes exec -ti $node -- ovs-vsctl set open . external_ids:ovn-bridge-mappings=physnet:breth0,tenantblue:ovsbr1,tenantred:ovsbr1
done
```

We must now configure the physical network; since the packets are leaving the
OVS bridge tagged with either the 10 or 20 VLAN, we must configure the physical
network where the virtualized nodes run to handle the tagged traffic.

For that we will create two VLANed interfaces, each with a different subnet; we
will need to know the name of the bridge the kind script created to implement
the extra network it required. Those VLAN interfaces also need to be configured
with an IP address:
```bash
OCI_BIN=podman | docker # choose your cup of tea.
$OCI_BIN network inspect underlay --format '{ .NetworkInterface }}'
podman3

# create the VLANs
ip link add link podman3 name podman3.10 type vlan id 10
ip addr add 192.168.123.1/24 dev podman3.10
ip link set dev podman3.10 up

ip link add link podman3 name podman3.20 type vlan id 20
ip addr add 192.168.124.1/24 dev podman3.20
ip link set dev podman3.20 up
```

**NOTE:** both the `tenantblue` and `tenantred` networks forward their traffic
to the `ovsbr1` OVS bridge.

#### Defining the OVN-Kubernetes networks
Let us now provision the attachment configuration for the two physical networks.
Notice they do not have a subnet defined, which means our workloads must
configure static IPs via cloud-init.
```yaml
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: tenantred
spec:
  config: |2
    {
            "cniVersion": "0.3.1",
            "name": "tenantred",
            "type": "ovn-k8s-cni-overlay",
            "topology": "localnet",
            "vlanID": 10,
            "netAttachDefName": "default/tenantred"
    }
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: tenantblue
spec:
  config: |2
    {
            "cniVersion": "0.3.1",
            "name": "tenantblue",
            "type": "ovn-k8s-cni-overlay",
            "topology": "localnet",
            "vlanID": 20,
            "netAttachDefName": "default/tenantblue"
    }
```

**NOTE:** each of the `tenantblue` and `tenantred` networks tags their traffic
with a different VLAN, which must be listed on the port `trunks` configuration.

#### Spin up the VMs
These two VMs can be used for the OVS bridge sharing scenario (two physical
networks share the same OVS bridge, each on a different VLAN).
```yaml
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-red-1
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: ovn-worker
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
          - name: physnet-red
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: physnet-red
        multus:
          networkName: tenantred
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
                eth0:
                  addresses: [ 192.168.123.10/24 ]
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-red-2
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: ovn-worker
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
          - name: flatl2-overlay
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: flatl2-overlay
        multus:
          networkName: tenantred
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
                eth0:
                  addresses: [ 192.168.123.20/24 ]
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-blue-1
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: ovn-worker
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
          - name: physnet-blue
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: physnet-blue
        multus:
          networkName: tenantblue
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
                eth0:
                  addresses: [ 192.168.124.10/24 ]
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: vm-blue-2
spec:
  running: true
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: ovn-worker
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
          - name: physnet-blue
            bridge: {}
        machine:
          type: ""
        resources:
          requests:
            memory: 1024M
      networks:
      - name: physnet-blue
        multus:
          networkName: tenantblue
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
                eth0:
                  addresses: [ 192.168.124.20/24 ]
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
```

#### Test East / West communication
You can check east/west connectivity between both **red** VMs via ICMP:
```bash
$ kubectl get vmi vm-red-2 -ojsonpath="{ @.status.interfaces }" | jq
[
  {
    "infoSource": "domain, guest-agent",
    "interfaceName": "eth0",
    "ipAddress": "192.168.123.20",
    "ipAddresses": [
      "192.168.123.20",
      "fe80::e83d:16ff:fe76:c1bd"
    ],
    "mac": "ea:3d:16:76:c1:bd",
    "name": "flatl2-overlay",
    "queueCount": 1
  }
]

$ virtctl console vm-red-1
Successfully connected to vm-red-1 console. The escape sequence is ^]

[fedora@vm-red-1 ~]$ ping 192.168.123.20
PING 192.168.123.20 (192.168.123.20) 56(84) bytes of data.
64 bytes from 192.168.123.20: icmp_seq=1 ttl=64 time=0.534 ms
64 bytes from 192.168.123.20: icmp_seq=2 ttl=64 time=0.246 ms
64 bytes from 192.168.123.20: icmp_seq=3 ttl=64 time=0.178 ms
64 bytes from 192.168.123.20: icmp_seq=4 ttl=64 time=0.236 ms

--- 192.168.123.20 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3028ms
rtt min/avg/max/mdev = 0.178/0.298/0.534/0.138 ms
```

The same behavior can be seen on the VMs attached to the **blue** network:
```bash
$ kubectl get vmi vm-blue-2 -ojsonpath="{ @.status.interfaces }" | jq
[
  {
    "infoSource": "domain, guest-agent",
    "interfaceName": "eth0",
    "ipAddress": "192.168.124.20",
    "ipAddresses": [
      "192.168.124.20",
      "fe80::6cae:e4ff:fefc:bd02"
    ],
    "mac": "6e:ae:e4:fc:bd:02",
    "name": "physnet-blue",
    "queueCount": 1
  }
]

$ virtctl console vm-blue-1
Successfully connected to vm-blue-1 console. The escape sequence is ^]

[fedora@vm-blue-1 ~]$ ping 
[fedora@vm-blue-1 ~]$ ping 192.168.124.20
PING 192.168.124.20 (192.168.124.20) 56(84) bytes of data.
64 bytes from 192.168.124.20: icmp_seq=1 ttl=64 time=0.531 ms
64 bytes from 192.168.124.20: icmp_seq=2 ttl=64 time=0.255 ms
64 bytes from 192.168.124.20: icmp_seq=3 ttl=64 time=0.688 ms
64 bytes from 192.168.124.20: icmp_seq=4 ttl=64 time=0.648 ms

--- 192.168.124.20 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3047ms
rtt min/avg/max/mdev = 0.255/0.530/0.688/0.169 ms
```

### Accessing the underlay services
We can now start HTTP servers listening to the IPs attached on the VLAN
interfaces:
```bash
python3 -m http.server --bind 192.168.123.1 9000 &
python3 -m http.server --bind 192.168.124.1 9000 &
```

And finally curl this from your client (blue network):
```bash
[fedora@vm-blue-1 ~]$ curl -v 192.168.124.1:9000
*   Trying 192.168.124.1:9000...
* Connected to 192.168.124.1 (192.168.124.1) port 9000 (#0)
> GET / HTTP/1.1
> Host: 192.168.124.1:9000
> User-Agent: curl/7.69.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
* HTTP 1.0, assume close after body
< HTTP/1.0 200 OK
< Server: SimpleHTTP/0.6 Python/3.11.3
< Date: Thu, 01 Jun 2023 16:05:09 GMT
< Content-type: text/html; charset=utf-8
< Content-Length: 2923
...
```

And from the client connected to the red network:
```bash
[fedora@vm-red-1 ~]$ curl -v 192.168.123.1:9000
*   Trying 192.168.123.1:9000...
* Connected to 192.168.123.1 (192.168.123.1) port 9000 (#0)
> GET / HTTP/1.1
> Host: 192.168.123.1:9000
> User-Agent: curl/7.69.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
* HTTP 1.0, assume close after body
< HTTP/1.0 200 OK
< Server: SimpleHTTP/0.6 Python/3.11.3
< Date: Thu, 01 Jun 2023 16:06:02 GMT
< Content-type: text/html; charset=utf-8
< Content-Length: 2923
< 
...
```

## Conclusions
In this post we have seen how to use OVN-Kubernetes to create secondary
networks connected to the physical underlay, allowing both east/west
communication between VMs, and access to services running outside the
Kubernetes cluster.

