---
layout: post
author: KubeVirt Maintainers
title: Announcing the release of KubeVirt v1.5
description: With the release of KubeVirt v1.5 we see the community adding some features that align with more traditional virtualization platforms.
navbar_active: 
pub-date: March 05
pub-year: 2025
category: news
tags:
  [
    "KubeVirt",
    "v1.5",
    "release",
    "community",
    "cncf",
    "milestone",
    "party time"
  ]

---

The KubeVirt Community is pleased to announce the release of [KubeVirt v1.5](https://github.com/kubevirt/kubevirt/releases/tag/v1.5.0). This release aligns with [Kubernetes v1.32](https://kubernetes.io/blog/2024/12/11/kubernetes-v1-32-release/) and is the seventh KubeVirt release to follow the Kubernetes release cadence. 

This release sees the project adding some features that are aligned with more traditional virtualization platforms, such as enhanced volume and VM migration, increased CPU performance, and more precise network state control.

You can read the full [release notes](https://kubevirt.io/user-guide/release_notes/#v150) in our user-guide, but we have included some highlights in this blog.

### Breaking change
Please be aware that in v1.5 we have [introduced a change](https://github.com/kubevirt/kubevirt/pull/13497) that affects permissions of namespace admins to trigger live migrations. As a hardening measure (principle of least privilege), the right of creating, editing and deleting `VirtualMachineInstanceMigrations` are no longer assigned by default to namespace admins.

For more information, see our post on the [KubeVirt blog](https://kubevirt.io/2025/Hardening-VMIM.html).

### Feature GA

This release marks the graduation of a number of features to GA; deprecating the feature gate and now enabled by default:

- [Migration Update Strategy and Volume Migration](https://kubevirt.io/user-guide/storage/volume_migration/): Storage migration can be useful in the cases where the users need to change the underlying storage, for example, if the storage class has been deprecated, or there is a new more performant driver available.
- [Auto Resource Limits](https://kubevirt.io/user-guide/compute/resources_requests_and_limits/): Automatically apply CPU limits to a VMI.
- VM Live Update Features: This feature underpins hotplugging of CPU, memory, and volume resources.
- [Network Binding Plugin](https://kubevirt.io/user-guide/network/network_binding_plugins/): A modular plugin which integrates with KubeVirt to implement a network binding.

### Compute

You can now specify the number of [IOThreads to use](https://kubevirt.io/user-guide/storage/disks_and_volumes/#iothreads) through virtqueue mapping to improve CPU performance. We also added [virtio video support for amd64](https://github.com/kubevirt/kubevirt/pull/13606) as well as the [ability to reset VMs](https://github.com/kubevirt/kubevirt/pull/13208), which provides the means to restart the guest OS without requiring a new pod to be scheduled.

### Networking

You can now [dynamically control the link state](https://kubevirt.io/user-guide/network/interfaces_and_networks/#link-state-management) (up/down) of a network interface.

### Scale and Performance

A comprehensive list of performance and scale benchmarks for the release is [available here](https://github.com/kubevirt/kubevirt/blob/main/docs/perf-scale-benchmarks.md). A notable change added to the benchmarks was the [virt-handler resource utilization metrics](https://github.com/kubevirt/kubevirt/pull/13250). This metric gives the avg, max and min memory/cpu utilization per VMI that is scheduled on the node where virt-handler is running. Another notable shoutout from the benchmark document is changing how [list calls are tracked](https://github.com/kubevirt/kubevirt/pull/12716). KubeVirt clients were misreporting watch calls as list calls, which was fixed in this release.

### Storage

With this release you can now migrate [hotplugged volumes](https://kubevirt.io/user-guide/storage/volume_migration/). You can also migrate VMIs with a volume shared using virtiofs. And we [addressed a recent change in libvirt](https://github.com/kubevirt/kubevirt/pull/13713) that was preventing some NFS shared volumes from migrating by providing shared filesystem paths upfront.

### Thank you for your contribution!
A lot of work from a [huge amount of people](https://kubevirt.devstats.cncf.io/d/66/developer-activity-counts-by-companies?orgId=1&var-period_name=v1.4.0%20-%20now&var-metric=contributions&var-repogroup_name=All&var-country_name=All&var-companies=All) goes into a release. A huge thank you to the 350+ people who contributed to this v1.5 release.

And if you're interested in contributing to the project and being a part of the next release, please check out our [contributing guide](https://kubevirt.io/user-guide/contributing/) and our [community membership guidelines](https://github.com/kubevirt/community/blob/main/membership_policy.md). 
                                                                                                                                        
Contributing needn't be designing a new feature or committing to a [Virtualization Enhancement Proposal](https://github.com/kubevirt/enhancements), there is always a need for reviews, help with our docs and website, or submitting good quality bugs. Every little bit counts.
