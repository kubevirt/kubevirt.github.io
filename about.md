---
title: About KubeVirt
layout: default
---

## Motivation

There is a wide range of management applications dealing with different
aspects of operating system and workload virtualization, i.e., oVirt (data
center, full OS virt), OpenStack (cloud, full OS virt) and OpenShift (cloud,
application containers). In terms of infrastructure they all have broadly
similar requirements for features such as API resource management, distributed
placement and scheduling, active workload management, and more besides. Currently
they all have completely separate implementations of these concepts with a high
level of technical duplication. At the low level, the only area of commonality
is sharing of [libvirt](https://libvirt.org) and [KVM](https://www.linux-kvm.org)
between [oVirt](https://ovirt.org) and [OpenStack](https://openstack.org).

* This is a poor use of developer resources because multiple projects are
  reinventing the same wheels.
* This is a poor experience for cloud administrators as they have to manually
  partition up their physical machines between the three separate applications,
  and then manage three completely separate pieces of infrastructure.
* This is a poor experience for tenant users because they have to learn three
  completely different application APIs and frontends depending on which
  particular type of workload they wish to run.

The Kubernetes container runtime(s) reliance on a shared kernel, provides
insufficient security isolation for certain deployment scenarios. Administrators
of such deployments may wish to be able to use hardware virtualization to
strongly separate untrusted workloads.

Users with existing applications may not be in a position to adopt the
application container model straightaway. Currently, they have to continue using
traditional data center virt or cloud virt applications for running these
existing applications in virtual machines. This results in having to manage two
distinct hosting platforms, making it difficult for these applications to
seemlessly integrate with modern container based applications. Running both
workload types on the same infrastructure reduces one barrier to transition
existing applications to an application container model.
