# Motivation

There is a wider range of management applications dealing with different
aspects of operating system and workload virtualization, i.e. oVirt (data
center, full OS virt), OpenStack (cloud, full OS virt) and OpenShift (cloud,
application containers). In terms of infrastructure they all have broadly
similar needs for API resource management, distributed placement and
scheduling, active workload management, etc. Currently they all have
completely separate implementations of these concepts with a high level of
technical duplication. At the low level, the only area of commonality is sharing 
of libvirt and KVM between oVirt and OpenStack.

* This is a poor use of developer resources because multiple projects are
  reinventing the same wheels.
* This is a poor experience for cloud administrators as they have to manually
  partition up their physical machines between the three separate
  applications, and then manage three completely separate pieces of
  infrastructure.
* This is a poor experience for tenant users because they have to learn three
  completely different application APIs and frontends depending on which
  particular type of workload they wish to run

While libvirt has been successful at providing a unified single-host centric
mangement API for virtualization apps to build upon, nothing similar has
arisen to fill the gap for network level compute management to the same degree.

The Kubernetes container runtime(s) reliance on a shared kernel, provides
insufficient security isolation for certain deployment scenarios.
Administrators of such deployments may wish to be able to use hardware
virtualization to strongly separate untrusted workloads.

Users with existing applications may not be in a position to adopt the
application container model straightaway. Currently they have to continue
using traditional data center virtualization or cloud virtualization
applications for running these existing applications in virtual machines.
This results in having to manage two distinct hosting platforms, making it
difficult for these applications to seemlessly integrate with modern container
based applications. Running both workload types on the same infrastructure
reduces one barrier to transition existing applications to an application
container model.


# Aims / goals

KubeVirt aims to serve as a building block for these use-cases, focusing on
providing the essential set of features for running virtualization workloads
on Kubernetes.

The high level goal of the project is to build a Kubernetes add-on to enable
management of KVM, via libvirt. The intent is that over the long term this
would enable application container workloads, and virtual machines, to be
managed from a single place via the Kubernetes native API and objects.

The project will provide a migration path to Kubernetes for existing
applications deployed in virtual machines, allowing them to more seemlessly
integrate with application container and take advantage of Kubernetes concepts.

* Expose an easy-to-use, common management interface
* Need for strong isolation of workloads
* Convenience to mix virtualization and container workloads on a cluster
* A way for a cloud administrator to host both types of workload with the same
  infrastructure and tools
