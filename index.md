---
layout: default
title: Run KVM on Kubernetes
---

The high level goal of the project is to build a Kubernetes add-on to enable
management of [KVM](https://www.linux-kvm.org), via
[libvirt](https://libvirt.org). The intent is that over the long term this would
enable application container workloads, and virtual machines, to be managed from
a single place via the [Kubernetes](https://kubernetes.io) native API and
objects. This will

* Provide a migration path to Kubernetes for existing applications deployed in
  virtual machines, allowing them to more seemlessly integrate with application
  container and take advantage of Kubernetes concepts
* Provide a converged API and object model for tenant users needing to manage
  both application containers and full OS image virtual machines
* Provide converged infrastructure for administrators wishing to support both
  application containers and full machine virtualization concurrently
* Facilitate the creation of virtual compute nodes to use KVM to strongly isolate
  application container PODs belonging to tenant users with differing trust
  levels

Read more about the [motivation for KubeVirt](/about).
