---
layout: post
author: Miguel Duarte Barroso
title: Dedicated Migration Networks for Cross-Cluster Live Migration with
  KubeVirt and EVPN
description: Learn how to configure a separate L2VNI for dedicated migration
  networks to enable secure, efficient cross-cluster live migration with
  KubeVirt and OpenPERouter.
navbar_active: Blogs
pub-date: November 26
pub-year: 2025
category: news
tags: ["kubevirt", "kubernetes", "evpn", "bgp", "openperouter", "network",
  "networking", "live-migration"]
comments: true
---

## Introduction

In our [previous post](https://kubevirt.io/2025/Stretched-layer2-network-between-clusters.html),
we explored how to stretch Layer 2 networks across multiple KubeVirt clusters
using EVPN and OpenPERouter. While this enables cross-cluster connectivity, VMs
often need to move between clusters. This happens during disaster recovery,
cluster maintenance, resource optimization, or compliance requirements.

Cross cluster live migration moves a running VM from one cluster to another
without stopping it. This generates substantial network traffic and needs
reliable, high-bandwidth connectivity. When you use the same network for both
application traffic and migration, you risk network congestion and security
issues from mixing migration traffic with user data.

A dedicated migration network solves this problem. By configuring a separate
Layer 2 Virtual Network Interface (L2VNI) for migration traffic, you isolate
this critical operation from application networking, improving both security and
performance. Furthermore, the cluster/network admins' lives are simplified by
making the dedicated migration network an overlay: instead of physically
running and maintaining new cables, configuring switches, and adding network
interfaces to each Kubernetes node (a complex and time-consuming underlay
network expansion), an L2VNI builds upon the existing physical network
infrastructure - admins can define and manage this overlay network logically,
making it a much more agile (and less disruptive) solution for dedicated
migration paths.

## Why should you have a dedicated migration network

Dedicated migration networks provide several key advantages:

- **Traffic Isolation**: Migration data flows through a separate network path,
preventing interference with application traffic and allowing for independent
network policies and monitoring.

- **Security Boundaries**: Migration traffic can be encrypted and routed through
dedicated security zones, reducing the attack surface and enabling fine-grained
access controls.

- **Performance Optimization**: Migration networks can be configured with
specific bandwidth allocations, MTU settings, and QoS policies optimized for
bulk data transfer.

- **Operational Visibility**: Separate networks enable dedicated monitoring and
troubleshooting of migration operations without impacting application network
analysis.

## Configuring the Dedicated Migration Network

Building on our previous multi-cluster setup, we'll now add a dedicated
migration network using a separate L2VNI. This configuration assumes you
already have the base clusters and stretched L2 network from the
[previous article](https://kubevirt.io/2025/Stretched-layer2-network-between-clusters.html).

### Prerequisites

Ensure you have:
- The multi-cluster testbed from the previous post deployed using
  `make deploy-multi-cluster`
- KubeVirt 1.6.2 or higher installed (included in
  `make deploy-multi-cluster`)
- Whereabouts IPAM CNI installed (included in `make deploy-multi-cluster`)
- The `DecentralizedLiveMigration` feature gate enabled (included in
  `make deploy-multi-cluster`)

### Configuring the Migration L2VNI

Now we'll create a separate L2VNI dedicated to migration traffic. Note that
we're using VNI 666 and VRF "rouge" to distinguish this from our application
network (VNI 110, VRF "red").

**NOTE:** this dedicated migration network (implemented by this L2VNI) is
pre-provisioned when you run `make deploy-multi-cluster`.

**Cluster A Migration Network:**

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl apply -f - <<EOF
apiVersion: openpe.openperouter.github.io/v1alpha1
kind: L2VNI
metadata:
  name: migration
  namespace: openperouter-system
spec:
  hostmaster:
    autocreate: true
    type: bridge
  l2gatewayip: 192.170.10.1/24
  vni: 666
  vrf: rouge
EOF
```

**Cluster B Migration Network:**

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-b kubectl apply -f - <<EOF
apiVersion: openpe.openperouter.github.io/v1alpha1
kind: L2VNI
metadata:
  name: migration
  namespace: openperouter-system
spec:
  hostmaster:
    autocreate: true
    type: bridge
  l2gatewayip: 192.170.10.1/24
  vni: 666
  vrf: rouge
EOF
```

### Creating Migration Network Attachment Definitions

Next, we create Network Attachment Definitions (NADs) for the migration
network. Note the reduced MTU of 1400 to account for VXLAN overhead:

**Cluster A Migration NAD:**

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl apply -f - <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: migration-evpn
  namespace: kubevirt
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "name": "migration-evpn",
      "type": "bridge",
      "bridge": "br-hs-666",
      "mtu": 1400,
      "ipam": {
        "type": "whereabouts",
        "range": "192.170.10.0/24",
        "exclude": [
          "192.170.10.1/32",
          "192.170.10.128/25"
        ]
      }
    }
EOF
```

**Cluster B Migration NAD:**

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-b kubectl apply -f - <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: migration-evpn
  namespace: kubevirt
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "name": "migration-evpn",
      "type": "bridge",
      "bridge": "br-hs-666",
      "mtu": 1400,
      "ipam": {
        "type": "whereabouts",
        "range": "192.170.10.0/24",
        "exclude": [
          "192.170.10.1/32",
          "192.170.10.0/25"
        ]
      }
    }
EOF
```

**NOTE:** these NADs are already pre-provisioned when you run
`make deploy-multi-cluster`.

#### Understanding the IP Range Strategy

Both clusters define the same 192.170.10.0/24 range but use different
exclusion patterns to avoid IP conflicts:

- **Cluster A** excludes `192.170.10.128/25` (192.170.10.128 to 192.170.10.255),
  giving it access to IPs 192.170.10.2 to 192.170.10.127
- **Cluster B** excludes `192.170.10.0/25` (192.170.10.0 to 192.170.10.127),
  giving it access to IPs 192.170.10.128 to 192.170.10.255
- Both exclude `192.170.10.1/32` (the gateway IP)

This approach ensures that VMs in each cluster get IPs from non-overlapping
ranges while maintaining the same L2 network, allowing seamless migration
without IP conflicts or the need for IP reassignment during the migration
process.

Since all the prerequisites including certificate exchange are handled by
`make deploy-multi-cluster`, we can proceed directly to preparing the VM to be
migrated. All the manifests and instructions are available in
[OpenPERouter cross-cluster live migration examples](https://github.com/openperouter/openperouter/blob/main/website/content/docs/examples/evpnexamples/kubevirt-multi-cluster.md#l2-vni-as-kubevirt-dedicated-migration-network-for-cross-cluster-live-migration).

## Cross-Cluster Live Migration in Action

Now let's demonstrate cross-cluster live migration using our dedicated
migration network. We'll create VMs that use both the application network
(evpn) and have an EVPN `L2VNI` as the migration network. Keep in mind that the
latter network is **not** plumbed into the VMs! It is used by the KubeVirt
agents (privileged components, which run in the Kubernetes nodes) to move
the migration between the different nodes (which happen to run in different
clusters).

### Creating Migration-Ready VMs

**VM in Cluster A (Migration Source):**

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl apply -f - <<EOF
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
            macAddress: 02:03:04:05:06:07
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
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.6.2
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
EOF
```

**VM in Cluster B (Migration Target):**

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-b kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-1
spec:
  runStrategy: WaitAsReceiver
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
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.6.2
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
EOF
```

As you can see, both VM definitions are the same - except the `runStrategy`.

### Performing the Cross Cluster Live Migration

To live-migrate the VM between clusters, we first need to wait for the source
VM to be ready:

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl wait vm vm-1 \
  --for=condition=Ready --timeout=60s
```

After that, we can create the migration receiver in cluster B:

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-b kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-target
spec:
  receive:
    migrationID: "cross-cluster-demo"
  vmiName: vm-1
EOF
```

We need to get the URL for the destination cluster migration agent. This
information will be required to provision the source cluster migration CR.
```shell
TARGET_IP=$(KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-b kubectl get vmim \
  migration-target -o jsonpath='{.status.synchronizationAddresses[0]}')
echo "Target migration IP: $TARGET_IP"
```

Now that we know the IP of the destination migration controller, we can initiate
the migration from cluster A:

```shell
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-source
spec:
  sendTo:
    connectURL: "${TARGET_IP}:9185"
    migrationID: "cross-cluster-demo"
  vmiName: vm-1
EOF
```

Monitor the migration progress:

```shell
# Watch migration status in cluster A
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-a kubectl get vmim \
  migration-source -w

# Watch VM status in cluster B
KUBECONFIG=$(pwd)/bin/kubeconfig-pe-kind-b kubectl get vm vm-1 -w
```

## Conclusion

Dedicated migration networks are essential for production KubeVirt deployments
that require VM mobility. Without traffic isolation, live migrations compete
with application workloads for bandwidth, potentially degrading service
performance and creating security risks by mixing operational traffic with user
data.

In this post, we have built upon the foundation laid in our
[previous article](https://kubevirt.io/2025/Stretched-layer2-network-between-clusters.html)
and enhanced our multi-cluster KubeVirt deployment with cross-cluster live
migration capabilities. We have configured a secondary `L2VNI` (VNI 666, VRF
"rouge") as a dedicated migration network between KubeVirt clusters. This
overlay network provides isolated, high-performance connectivity for migration
operations without requiring additional physical infrastructure. By using EVPN
and OpenPERouter, we demonstrated how cross-cluster live migration works in
practice while maintaining complete separation from application networking.

This setup enables organizations to achieve workload mobility across clusters
with the security, performance, and operational visibility required for
production environments. The overlay approach simplifies management by avoiding
the complexity of physical network expansion while providing the dedicated
bandwidth and monitoring capabilities that enterprise migrations demand.
