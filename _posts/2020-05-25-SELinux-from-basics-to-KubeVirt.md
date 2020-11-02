---
layout: post
author: Jed Lejosne
description: This blog details step by step how SELinux is leveraged in KubeVirt to isolate virtual machines from each other.
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "design",
    "architecture",
    "security",
    "libvirt",
    "qemu"
  ]
comments: true
title: SELinux, from basics to KubeVirt
pub-date: May 25
pub-year: 2020
---
SELinux is one of many security mechanisms leveraged by KubeVirt.  
For an overview of KubeVirt security, please first read [this excellent article]({% post_url 2020-04-29-KubeVirt-Security-Fundamentals %}).

## SELinux 101

At its core, SELinux is a whitelist-based security policy system intended to limit interactions between Linux processes and files. Simplified, it can be visualized as a "syscall firewall".

Policies are based on statically defined types, that can be assigned to files, processes and other objects.

A simple policy example would be to allow a `/bin/test` program to read its `/etc/test.conf` configuration file.

The policy for that would include directives to:
* Assign types to files and processes, like `test_bin_t` for `/bin/test`, `test_conf_t` for `/etc/test.conf`, and `test_t` for instances of the test program
* Configure a *transition* from `test_bin_t` to `test_t`
* Allow `test_t` processes to read `test_conf_t` files.

## The SELinux standard Reference Policy

Since SELinux policies are whitelists, a setup running with the above policy would not be allowed to do anything, except for that test program.

A policy for an entire Linux distribution as seen in the wild is made of millions of lines, which wouldn't be practical to write and maintain on a per-distribution basis.

That is why the [Reference Policy](https://github.com/SELinuxProject/refpolicy) (refpolicy) was written. The refpolicy implements various mechanisms to simplify policy writing, but also contains modules for most core Linux applications.

Most use-cases can be addressed with the "standard" refpolicy, plus optionally some custom modules for specific applications not covered by the Reference Policy.

Limitations start to arise for use-cases that run the same binary multiple times concurrently, and expect instances to be isolated from each other. Virtualization is one of those use cases. Indeed if 2 virtual machines are running on the same system, it is usually desirable that one VM can't see the resources of the other one.

As an example, if qemu processes are labeled `qemu_t` and disk files are labeled `qemu_disk_t`, allowing `qemu_t` to read/write `qemu_disk_t` files would allow all qemu processes to access all disk files.

Another mechanism is necessary to provide VM isolation. That is what SELinux MCS addresses.

## SELinux Multi-Category Security (MCS)

Multi-Category Security, or MCS, provides the ability to dynamically add numerical IDs (called categories) to any SELinux type on any object (file/process/socket/...).

Categories range from 0 to 1023. Since only 1024 unique IDs would be quite limiting, most virtualization-related applications combine 2 categories, which add up to about 500,000 combinations. It's important to note that categories have no order, so `c42,c42` is equivalent to `c42`, and `c1,c2` is equivalent to `c2,c1`.

In the example above, we can now:
* Dynamically compute a unique random category for each VM
* Assign the corresponding categories to all VM resources, like qemu instance and disk files
* Only allow access when all the involved resources have the same category number.

And that is exactly what libvirt does when compiled with SELinux support, as shown in the diagram below.

![Components View](/assets/2020-05-25-SELinux-from-basics-to-KubeVirt/libvirt.svg)

Note: MCS can do a lot more, this article only describes the bits that are used by libvirt and kubernetes.

### MCS and containers

Another application that leverages MCS is Linux containers.

In fact, containers use very few SELinux types and rely mostly on MCS to provide container isolation. For example, all the files and processes in container filesystems have the same SELinux types. For a non-super-privileged container, those types are usually `container_file_t` for file and `container_t` for processes. Most operations are permitted within those types, and the categories are really what matters.

As with libvirt, categories have to match for access to be granted, effectively blocking inter-container communication.

Super-privileged containers however are exempt from categories. They use the `spc_t` SELinux type, which allows them to do pretty much anything, at least as far as SELinux is concerned.

That is all defined as an SELinux module in the [container-selinux Github repository](https://github.com/containers/container-selinux)

### MCS and container orchestrators

Container orchestrators add a level of management. They define pods of containers, and within a pod, cross-container communication is acceptable and often even necessary.

Categories are therefore managed at the pod level, and all the containers that belong to the same pod are assigned the same categories, as illustrated by the following diagram.

![Components View](/assets/2020-05-25-SELinux-from-basics-to-KubeVirt/kubernetes.svg)

## SELinux in Kubevirt

Finally getting to KubeVirt, which relies on all of the above, as it runs libvirt in a container managed by a container orchestrator on SELinux-enabled systems.

In that context, libvirt runs inside a regular container and can't manage SELinux object like types and categories. However, MCS isolation is provided by the container orchestrator, and every VM runs in its own pod (virt-launcher). And since no 2 virt-launcher pods will ever have the same categories on a given node, SELinux isolation of VMs is guaranteed.

![Components View](/assets/2020-05-25-SELinux-from-basics-to-KubeVirt/kubevirt.svg)

Note: As some host configuration is usually required for VMs to run, each node also runs a super-privileged pod (virt-handler), dedicated to such operations.
