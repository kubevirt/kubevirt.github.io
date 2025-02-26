---
layout: post
author: tiraboschi
title: VirtualMachineInstanceMigrations RBAC hardening
description: Apply the principle of least privilege (PoLP) to VirtualMachineInstanceMigrations
navbar_active: Blogs
pub-date: February 26
pub-year: 2025
category: news
tags:
  [
    "VMIM",
    "migrate",
    "migrations",
    "RBAC",
    "hardening",
    "security",
    "v1.5"
  ]
comments: true
---

### Context
The request to live migrate a VM is represented by a `VirtualMachineInstanceMigration` instance.
A VirtualMachineInstanceMigration (VMIM) is a namespaced CRD, and its instances are expected to be in the namespace of the VM they refer to.

Up to KubeVirt v1.4, by default, a namespace admin (usually a namespace "owner" in a less formal definition) was able to create VMs and also VMIM objects to enqueue a live migration request for a VM within their namespace.
At the same time, live migrations can be triggered as part of critical infrastructure operations like node drains or upgrades, which are the domain of cluster admins. <br>
So, if namespace admins can continuously enqueue migration requests or delete scheduled VMIM objects needed for ongoing infrastructure-critical operations, they could delay or even prevent cluster-critical operations started by cluster admins, a role with greater privileges.

It was therefore possible that a malicious, lesser-privileged user could abuse this, causing a kind of DoS at the cluster level.
Even worse, Kubernetes RBAC permissions are purely additive (there are no "deny" rules), and KubeVirt roles are constantly reconciled by the virt-operator, so even a cluster admin who was aware of the issue was unable to deny these permissions as a precautionary measure.

For this reason, starting from KubeVirt v1.5, create/delete/update rights will no longer be granted by default to all namespace admins, in accordance with the principle of least privilege.
A new convenient ClusterRole named `kubevirt.io:migrate` has been introduced to allow cluster admins to easily grant this permission to selected users.

### Side effects on hotplug operations
Device hotplug operations, at least for CPU and memory, implicitly trigger a live migration executed by the virt-controller on behalf of the user. These operations will not be affected by this change. Under some circumstances or cluster configurations, live migrations are not automatically triggered when NIC devices are hotplugged. In such cases, the only option for namespace admins is to request VMIM permissions from a cluster admin to manually trigger the migration or concatenate two device hotplug operations (where the second one will implicitly complete the NIC hotplug).

### Cluster-admin tasks
A cluster admin can bind the new kubevirt.io:migrate ClusterRole to selected trusted users/groups at the namespace scope using:
~~~ bash
kubectl create -n usernamespace rolebinding kvmigrate --clusterrole=kubevirt.io:migrate --user=user1 --user=user2 --group=group1
~~~
or at the cluster scope:
~~~ bash
kubectl create clusterrolebinding kvmigrate --clusterrole=kubevirt.io:migrate --user=user1 --user=user2 --group=group1
~~~

A cluster admin can also restore the previous behavior (where all namespace admins are allowed to manage migrations) with:
~~~ bash
kubectl label --overwrite clusterrole kubevirt.io:migrate rbac.authorization.k8s.io/aggregate-to-admin=true
~~~

A highly cautious cluster admin who does not want any disruption due to the upgrade process could still create a temporary ClusterRole for migration before the upgrade, labeling it with `rbac.authorization.k8s.io/aggregate-to-admin=true`.
For example:
~~~ yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    rbac.authorization.k8s.io/aggregate-to-admin=true
  name: kubevirt.io:upgrademigrate
rules:
- apiGroups:
  - subresources.kubevirt.io
  resources:
  - virtualmachines/migrate
  verbs:
  - update
- apiGroups:
  - kubevirt.io
  resources:
  - virtualmachineinstancemigrations
  verbs:
  - get
  - delete
  - create
  - update
  - patch
  - list
  - watch
  - deletecollection
~~~
This ClusterRole will be aggregated into the `admin` role before the KubeVirt upgrade, and the upgrade process will not modify it, ensuring the previous behavior is maintained.
After the upgrade, the cluster admin will have sufficient time to bind the new `kubevirt.io:migrate` ClusterRole to selected users before removing the temporary ClusterRole.
