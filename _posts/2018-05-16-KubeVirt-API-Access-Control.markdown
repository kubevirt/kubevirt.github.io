---
layout: post
author: davidvossel
description: How User Access Control works in KubeVirt
navbar_active: Blogs
pub-date: May 16
pub-year: 2018
category: uncategorized
tags: [api, rbac, roles]
comments: true
---

Access to KubeVirt resources are controlled entirely by Kubernete's Resource
Based Access Control (RBAC) system. This system allows KubeVirt to tie directly
into the existing authentication and authorization mechanisms Kubernetes
already provides to its core api objects.

## KubeVirt RBAC Role Basics

Typically, when people think of Kubernetes RBAC system, they're thinking about
granting users access to create/delete kubernetes objects (like Pods,
deployments, etc), however those same RBAC mechanisms work naturally with
KubeVirt objects as well.

When we look at KubeVirt's objects, we can see they are structured just like
the objects that come predefined in the Kubernetes core.

For example, look here's an example of a VirtualMachine spec.

```
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: vm-ephemeral
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
        volumeName: containerdisk
    resources:
      requests:
        memory: 64M
  volumes:
  - name: containerdisk
    containerDisk:
      image: kubevirt/cirros-container-disk-demo:devel
```

In the spec above, we see the KubeVirt VirtualMachine object has an _apiVersion_
field and a _kind_ field just like a Pod spec does. The **kubevirt.io** portion
of the apiVersion field represents KubeVirt apiGroup the resource is a part of.
The **kind** field reflects the resource type.

Using that information, we can create an RBAC role that gives a user permission
to create, delete, and view all VirtualMachine objects.

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: vm-access
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - kubevirt.io
    resources:
      - virtualmachines
    verbs:
      - get
      - delete
      - create
      - update
      - patch
      - list
      - watch
```

This same logic can be applied when creating RBAC roles for other KubeVirt
objects as well. If we wanted to extend this RBAC role to grant similar
permissions for VirtualMachinePreset objects, we'd just have to add a second
resource kubevirt.io resource list. The result would look like this.

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: vm-access
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - kubevirt.io
    resources:
      - virtualmachines
      - virtualmachinepresets
    verbs:
      - get
      - delete
      - create
      - update
      - patch
      - list
      - watch
```

## KubeVirt Subresource RBAC Roles

Access to a VirtualMachines's VNC and console stream using KubeVirt's
**virtctl** tool is managed by the Kubernetes RBAC system as well. Permissions
for these resources work slightly different than the other KubeVirt objects
though.

Console and VNC access is performed using the KubeVirt Stream API, which has
its own api group called **subresources.kubevirt.io**. Below is an example of
how to create a role that grants access to the VNC and console streams APIs.

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: vm-vnc-access
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachines/console
      - virtualmachines/vnc
    verbs:
      - get
```

## Limiting RBAC To a Single Namespace.

A ClusterRole can be bound to a user in two different ways.

When a ClusterRoleBinding is used, a user is permitted access to all resources
defined in the ClusterRole across all namespaces in the cluster.

When a RoleBinding is used, a user is limited to accessing only the resources
defined in the ClusterRole within the namespace RoleBinding exists in.

## Limiting RBAC To a Single Resource.

A user can also be limit to accessing only a single resource within a resource
type. Below is an example that only grants VNC access to the VirtualMachine
named 'bobs-vm'

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: vm-vnc-access
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachines/console
      - virtualmachines/vnc
    resourceName:
      - bobs-vm
    verbs:
      - get
```

## Default KubeVirt RBAC Roles

The next release of KubeVirt is coming with three default ClusterRoles that
admins can use to grant users access to KubeVirt resources. In most cases,
these roles will prevent admins from ever having to create their own custom
KubeVirt RBAC roles.

More information about these default roles can be found in the KubeVirt
user guide [here](https://kubevirt.io/user-guide/#/installation/authorization)
