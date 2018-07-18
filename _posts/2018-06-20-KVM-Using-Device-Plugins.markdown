---
layout: post
author: stu-gott
description: KubeVirt Using Device Plugins For KVM
navbar_active: Blogs
pub-date: June 20
pub-year: 2018
category: news
comments: true
---

As of Kubernetes 1.10, the Device Plugins API is now in beta! KubeVirt is now
using this framework to provide hardware acceleration and network devices to
virtual machines. The motivation behind this is that virt-launcher pods are no
longer responsible for creating their own device nodes. Or stated another way:
virt-launcher pods no longer require excess privileges just for the purpose of
creating device nodes.

## Kubernetes Device Plugin Basics

Device Plugins consist of two main parts: a server that provides devices and
pods that consume them. Each plugin server is used to share a preconfigured
list of devices local to the node with pods scheduled on that node. Kubernetes
marks each node with the devices it's capable of sharing, and uses the presence
of such devices when scheduling pods.

## Device Plugins In KubeVirt

### Providing Devices

In KubeVirt virt-handler takes on the role of the device plugin server. When it
starts up on each node, it registers with the Kubernetes Device Plugin API and
advertises KVM and TUN devices.

```
apiVersion: v1
kind: Node
metadata:
  ...
spec:
  ...
status:
  allocatable:
    cpu: "2"
    devices.kubevirt.io/kvm: "110"
    devices.kubevirt.io/tun: "110"
    pods: "110"
    ...
  capacity:
    cpu: "2"
    devices.kubevirt.io/kvm: "110"
    devices.kubevirt.io/tun: "110"
    pods: "110"
    ...
```

In this case advertising 110 KVM or TUN devices is simply an arbitrary default
based on the number of pods that node is limited to.

### Consuming Devices

Now any pod that requests a `devices.kubevirt.io/kvm` or
`devices.kubevirt.io/tun` device can only be scheduled on nodes which provide
them. On clusters where KubeVirt is deployed this conveniently happens to be
all nodes in the cluster that have these physical devices, which normally means
all nodes in the cluster.

Here's an excerpt of what the pod spec looks like in this case.

```
apiVersion: v1
kind: Pod
metadata:
  ...
spec:
  containers:
  - command:
    - /entrypoint.sh
      ...
    name: compute
      ...
    resources:
      limits:
        devices.kubevirt.io/kvm: "1"
        devices.kubevirt.io/tun: "1"
      requests:
        devices.kubevirt.io/kvm: "1"
        devices.kubevirt.io/tun: "1"
        memory: "161679432"
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
      privileged: false
      runAsUser: 0
    ...
```

Of special note is the securityContext stanza. The only special privilege
required is the `NET_ADMIN` capability! This is needed by libvirt to set up the
domain's networking stack.
