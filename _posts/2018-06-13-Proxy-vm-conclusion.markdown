---
layout: post
author: SchSeba
description: This is a roadmap blog post for the network implementation in the kubevirt project
---

# Introduction
This blog post follow my previous reseach on how to allow vms inside a k8s cluster tp play nice with istio and other sidecars.


# Research conclusions and network roadmap

After the deep research about different options/ways to connect VM to pods, we find that all the solution have different pros and cons.
All the represented solution need access to kernel modules and have the risk of conflicting with other networking tools.

We decided to implement a 100% Kubernetes compatible network approach on the kubevirt project by using the slirp interface qemu provides.
This approach let the VM (from a networking perspective) behave like a process. Thus all traffic is going in and out of TCP or UDP sockets. The approach especially needs to avoid to rely on any specific Kernel configurations (like iptables, ebtables, tc, …) in order to not conflict with other Kubernetes networking tools like Istio or multus.

This is just an intermediate solution, because it's shortcomings (unmaintained, unsafe, not performing well)

### Slirp interface

Pros:
* vm ack like a process
* No external modules needed
* No external process needed
* Works with any sidecar solution
* no rely on any specific Kernel configurations
* pod can run without privilege

Cons:
* poor performance
* use userspace network stack

### Iptables only

Pros:
* No external modules needed
* No external process needed
* All the traffic is handled by the kernel user space not involved

Cons:
* <span style="color:red;">Istio dedicated solution!</span>
* Not other process can change the iptables rules

### Iptables with a nat-proxy

Pros:
* No external modules needed
* Works with any sidecar solution

Cons:
* Not other process can change the iptables rules
* External process needed
* The traffic is passed to user space
* Only support ingress TCP connection 

### Iptables with a trasperent-proxy

Pros:
* other process can change the nat table (this solution works on the mangle table)
* better preformance comparing to nat-proxy
* Works with any sidecar solution

Cons:
* Need NET_ADMIN capability for the docker
* External process needed
* The traffic is passed to user space
* Only support ingress TCP connection 