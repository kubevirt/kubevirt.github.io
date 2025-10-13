---
layout: post
author: Miguel Duarte Barroso
title: Stretching a layer2 network over multiple KubeVirt clusters
description: How to stretch a layer2 overlay over multiple KubeVirt clusters.
navbar_active: Blogs
pub-date: October 13
pub-year: 2025
category: news
tags: ["kubevirt", "kubernetes", "evpn", "bgp", "openperouter", "network", "networking"]
comments: true
---

## Introduction
KubeVirt enables running virtual machines (VM) within Kubernetes clusters, but
networking VMs across multiple clusters presents significant challenges.
Current KubeVirt networking relies on cluster-local solutions, which cannot
extend Layer 2 broadcast domains beyond cluster boundaries. This limitation
forces applications requiring L2 connectivity to either remain within single
clusters or undergo complex network reconfiguration when distributed across
clusters.

This integration addresses a fundamental limitation in distributed KubeVirt
deployments: the inability to maintain L2 adjacency between VMs running on
different clusters. By leveraging EVPN's BGP-based control plane and advanced
MAC/IP advertisement mechanisms, we can now stretch Layer 2 broadcast domains
across geographically distributed KubeVirt clusters, creating a unified network
fabric that treats multiple clusters as a single, cohesive infrastructure.

### Why Stretch L2 Networks across different clusters ?
The ability to extend L2 domains between KubeVirt clusters unlocks several
critical capabilities that were previously difficult to achieve.
Traditional cluster networking creates isolation boundaries that, while
beneficial for security and resource management, can become barriers when
applications require tight coupling or when operational requirements demand
flexibility in workload placement.

All in all, stretching an L2 domain across cluster boundaries enables use cases
that are fundamental to infrastructure reliability and flexibility, which include:
- **Cross Cluster Live Migration:** VMs must migrate between clusters without
requiring IP address changes, DNS updates,or application reconfiguration. This
capability is essential for disaster recovery scenarios where VMs must failover
to geographically distant clusters while maintaining their network identity and
established connections.
- **Legacy enterprise applications availability:** many mission-critical
workloads were designed with assumptions about L2 adjacency—database clusters
requiring heartbeat mechanisms over broadcast domains, application servers
expecting multicast discovery, or network-attached storage systems relying on
L2 protocols.
- **Resource optimization and capacity planning:** organizations can distribute
VM workloads based on compute availability, cost considerations, or compliance
requirements while maintaining the network simplicity that applications expect.
This flexibility becomes particularly valuable in hybrid cloud scenarios where
workloads may need to seamlessly span on-premises KubeVirt clusters and
cloud-hosted instances.

This is where the power of EVPN comes into play: by integrating EVPN into the
KubeVirt ecosystem, we can create a sophisticated L2 overlay. Think of it as a
virtual network fabric that stretches across your data centers or cloud
regions, enabling the workloads running in KubeVirt clusters to attach to a
single, unified L2 domain.

In this post, we’ll dive into how this powerful combination works and how it
unlocks true application mobility for your virtualized workloads on Kubernetes.

## Prerequisites
- container runtime - docker - installed in your system
- git
- make

## The testbed
The testbed will be implemented using a physical network deployed in
leaf/spine topology, which is a common two-layer network architecture used in
data centers. It consists of leaf switches that connect to end devices, and
spine switches that interconnect all leaf switches. This way, workloads will
always be (at most) two hops away from one another.

![This diagram portrays the testbed we will use for this blog article.](/assets/2025-10-13-evpn-integration/01-evpn-integration-testbed.png "The testbed we will use")

The diagram highlights the autonomous system (AS) numbers each of the
components will use.

We can infer from the AS numbers provided above the testbed will feature eBGP
configuration, thus providing routing between different autonomous systems.

We will setup the testbed using [containerlab](https://containerlab.dev/), and
the Kubernetes clusters are deployed using [KinD](https://kind.sigs.k8s.io/).
The BGP speakers (routers) in each leaf are implemented using
[FRR](https://frrouting.org/).

### Spawning the testbed on your laptop
To spawn the tested in your laptop, you should clone the openperouter repo.
```sh
git clone https://github.com/openperouter/openperouter.git
```

Assuming you have all the [requirements](#prerequisites) installed in your
laptop, all you need to do is build the router component, and execute the
`deploy-multi` make target. Then, you should be ready to go!
```sh
make docker-build && make deploy-multi
```

After running this make target, you should have deployed the testbed as shown
in the testbed's [diagram](#the-testbed); one thing is missing though: the
autonomous systems in the kind clusters are not configured yet! This will be
configured in the [next section](#configuring-the-kubevirt-clusters).

The kubeconfigs to connect to each cluster can be found in `openperouter`'s
`bin` directory:
```shell
ls $(pwd)/bin/kubeconfig-*
/root/github/openperouter/bin/kubeconfig-pe-kind-a  /root/github/openperouter/bin/kubeconfig-pe-kind-b
```

## Configuring the KubeVirt clusters
As indicated in the [introduction](#introduction) section, the end goal is to
stretch a layer 2 network across both Kubernetes clusters, using EVPN. Please
refer to the image below for a simple diagram.

![A layer 2 network which is stretched across both Kubernetes clusters using EVPN](/assets/2025-10-13-evpn-integration/02-stretched-l2-evpn.png "Layer 2 network stretched across both clusters")

In order to stretch an L2 overlay across both cluster we need to:
- configure the underlay network
- configure the EVPN VXLAN VNI

We will rely on [openperouter](https://openperouter.github.io/) for both of
these.

Let's start with the underlay network, in which we will connect the Kubernetes
clusters to each cluster's top of rack BGP/EVPN speaker.

### Configuring the underlay network
The first thing we need to do is to finish setting up the testbed; we need to
peer our two Kubernetes clusters with the BGP/EVPN speaker in each cluster's
top of rack: `kindleaf-a` for cluster-a, `kindleaf-b` for cluster-b.
This will require you to specify the expected AS numbers, to define the VXLAN
tunnel endpoint addresses, and also specify which node interface will be used
to connect to external routers.

For that,
you will need to provision the following CRs:

- in cluster A.
```yaml
apiVersion: openpe.openperouter.github.io/v1alpha1
kind: Underlay
metadata:
  name: underlay
  namespace: openperouter-system
spec:
  asn: 64514
  evpn:
    vtepcidr:  100.65.0.0/24
  nics:
    - toswitch
  neighbors:
    - asn: 64512
      address: 192.168.11.2
```

- in cluster B.
```yaml
apiVersion: openpe.openperouter.github.io/v1alpha1
kind: Underlay
metadata:
  name: underlay
  namespace: openperouter-system
spec:
  asn: 64518
  evpn:
    vtepcidr: 100.65.1.0/24
  routeridcidr: 10.0.1.0/24
  nics:
    - toswitch
  neighbors:
    - asn: 64516
      address: 192.168.12.2
```

[!IMPORTANT]
Remember that you need to point at the proper kubeconfig file to
connect to the desired cluster.
To provision the manifest into cluster-A you would do something like the
following:
```shell
cd <path to openperouter repo>
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl apply -f <manifest>
```

### Configuring the EVPN VNI
Once we have configured both Kubernetes cluster's peering with the external
routers in each kind leaves, we can now focus on defining the layer2 EVPN. For
that, we will use openperouter's `L2VNI` CRD.

The configuration is the same for both clusters; please provision the following
`L2VNI` CR in both clusters:

```yaml
apiVersion: openpe.openperouter.github.io/v1alpha1
kind: L2VNI
metadata:
  name: layer2
  namespace: openperouter-system
spec:
  hostmaster:
    autocreate: true
    type: bridge
  l2gatewayip: 192.170.1.1/24
  vni: 110
  vrf: red
```

After this step, we will have created an L2 overlay network on top of the
network fabric. We now need to enable it to be plumbed to the workloads. And
for that, we will need to provision a network attachment definition (again, in
both clusters).

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: evpn
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "name": "evpn",
      "type": "bridge",
      "bridge": "br-hs-110",
      "macspoofchk": false,
      "disableContainerInterface": true
    }
```
 
Now that we have set up networking for the workloads, we can proceed with
actually instantiating the VMs which will attach to this network overlay.

### Provisioning and running the VM workloads

You will have one VM running in cluster A (vm-1), and another VM running in
cluster B (vm-2).

The VM's will each have one network interface, attached to the layer2 overlay.
The VMs are using bridge binding, and they attach to the overlay using bridge-cni.
Both VMs have static IPs, configured over cloud-init. They are:

| VM name | Cluster   | IP address   |
|---------|-----------|--------------|
| vm-1    | pe-kind-a | 192.170.1.3  |
| vm-2    | pe-kind-b | 192.170.1.30 |

To provision these, follow these steps:

1. provision `vm-1` in cluster `pe-kind-a`:
```yaml
 apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-1
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-1
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      domain:
        devices:
          interfaces:
          - bridge: {}
            name: evpn
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
        resources:
          requests:
            memory: 2048M
        machine:
          type: ""
      networks:
      - multus:
          networkName: evpn
        name: evpn
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.5.2
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            version: 2
            ethernets:
              eth0:
                addresses:
                - 192.170.1.3/24
                gateway4: 192.170.1.1
        name: cloudinitdisk
```

2. provision `vm-2` in cluster `pe-kind-b`:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-2
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-2
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      domain:
        devices:
          interfaces:
          - bridge: {}
            name: evpn
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
        resources:
          requests:
            memory: 2048M
        machine:
          type: ""
      networks:
      - multus:
          networkName: evpn
        name: evpn
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.5.2
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            version: 2
            ethernets:
              eth0:
                addresses:
                - 192.170.1.30/24
                gateway4: 192.170.1.1
        name: cloudinitdisk
```

We will use `VM-2` (which runs in cluster **B**) as the "server", and `VM-1`
(which runs in cluster **A**) as the "client"; before doing any of that, let's
wait for the VMs to become `Ready`:
```shell
KUBECONFIG=bin/kubeconfig-pe-kind-a kubectl wait vm vm-1 --for=condition=Ready --timeout=60s
KUBECONFIG=bin/kubeconfig-pe-kind-b kubectl wait vm vm-2 --for=condition=Ready --timeout=60s
```

Now that we know the VMs are `Ready`, let's confirm the IP address for `VM-2`,
and reach into it from the `VM-1` VM, which is available in cluster A.

```sh
KUBECONFIG=bin/kubeconfig-pe-kind-b kubectl get vmi vm-2 -ojsonpath="{.status.interfaces[0].ipAddress}"
192.170.1.30
```

Let's now serve some data. We will use a toy python webserver for that, which serves some files:
```shell
[fedora@vm-2 ~]$ touch $(date)
[fedora@vm-2 ~]$ ls -la
total 12
drwx------. 1 fedora fedora 122 Oct 13 12:08 .
drwxr-xr-x. 1 root   root    12 Sep 13  2024 ..
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 12:08:15
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 13
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 2025
-rw-r--r--. 1 fedora fedora  18 Jul 21  2021 .bash_logout
-rw-r--r--. 1 fedora fedora 141 Jul 21  2021 .bash_profile
-rw-r--r--. 1 fedora fedora 492 Jul 21  2021 .bashrc
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 Mon
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 Oct
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 PM
drwx------. 1 fedora fedora  30 Sep 13  2024 .ssh
-rw-r--r--. 1 fedora fedora   0 Oct 13 12:08 UTC
[fedora@vm-2 ~]$ python3 -m http.server 8090
Serving HTTP on 0.0.0.0 port 8090 (http://0.0.0.0:8090/) ...
```

And let's try to access that from the VM which runs in the other cluster:
```shell
KUBECONFIG=bin/kubeconfig-pe-kind-a virtctl console vm-1
# password to access the VM is fedora/fedora
[fedora@vm-1 ~]$ curl 192.170.1.30:8090
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href=".bash_logout">.bash_logout</a></li>
<li><a href=".bash_profile">.bash_profile</a></li>
<li><a href=".bashrc">.bashrc</a></li>
<li><a href=".ssh/">.ssh/</a></li>
<li><a href="12%3A08%3A15">12:08:15</a></li>
<li><a href="13">13</a></li>
<li><a href="2025">2025</a></li>
<li><a href="Mon">Mon</a></li>
<li><a href="Oct">Oct</a></li>
<li><a href="PM">PM</a></li>
<li><a href="UTC">UTC</a></li>
</ul>
<hr>
</body>
</html>
```

As you can see, the VM running in cluster A was able to successfully reach into
the VM running in cluster B.

## Conclusions
In this article we have explained EVPN and which virtualization use cases it
can provide.

We have also shown the reader how
[openperouter](https://openperouter.github.io/) `L2VNI` CRD can be used to
stretch a layer2 overlay across multiple Kubernetes clusters.
