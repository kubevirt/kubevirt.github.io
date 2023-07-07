---
layout: post
author: KubeVirt Maintainers
title: KubeVirt v1.0 has landed!
description: We are very pleased to announce the release of KubeVirt v1.0!
navbar_active: 
pub-date: July 11
pug-year: 2023
category: news
tags:
  [
    "KubeVirt",
    "v1.0",
    "release",
    "community",
    "cncf",
    "milestone",
    "party time"
  ]

---

The KubeVirt community is proud to announce the release of [KubeVirt v1.0](https://github.com/kubevirt/kubevirt/releases/tag/v1.0.0)! This release demonstrates the accomplishments of the community and user adoption over the years and represents an important milestone for everyone involved.

## A brief history
The KubeVirt project started in Red Hat at the end of 2016, with the question: Can virtual machines (VMs) run in containers and be deployed by Kubernetes?
It proved to be not only possible, but quickly emerged as a promising solution to the future of virtual machines in the container age.
KubeVirt joined the [CNCF](https://www.cncf.io/) as a Sandbox project in September 2019, and an Incubating project in April 2022.
From a handful of people hacking away on a proof of concept, KubeVirt has grown into 45 active repositories, with the primary [kubevirt/kubevirt](https://github.com/kubevirt/kubevirt) repo having 17k commits and 1k forks.

## What does v1.0 mean to the community?
The v1.0 release signifies the incredible growth that the community has gone through in the past six years from an idea to a production-ready Virtual Machine Management solution. The next stage with v1.0 is the additional focus on maintaining APIs while continuing to grow the project. This has led KubeVirt to adopt community practices from Kubernetes in key parts of the project.

Leading up to this release we had a shift in release cadence: from monthly to 3 times a year, following the Kubernetes release model. This allows our developer community additional time to ensure stability and compatibility, our users more time to plan and comfortably upgrade, and also aligns our releases with Kubernetes to simplify maintenance and supportability.

The theme 'aligning with Kubernetes' is also felt through the other parts of the community, by following their governance processes; introducing SIGs to split test and review responsibilities, as well as a SIG release repo to handle everything related to a release; and regular [SIG meetings](https://calendar.google.com/calendar/u/0/embed?src=kubevirt@cncf.io) that now include SIG scale and performance and SIG storage alongside our weekly Community meetings.

## What’s included in this release?

This release demonstrates the accomplishments of the community and user adoption over the past many months. The full list of feature and bug fixes can be found in our [release notes](https://github.com/kubevirt/kubevirt/releases/tag/v1.0.0), but we’ve also asked representatives from some of our SIGs for a summary.

### SIG-scale
KubeVirt’s SIG-scale drives the performance and scalability initiatives in the community. Our focus for the v1.0 release was on sharing the performance results over the past 6 months. The benchmarks since December 2022 which cover the past two release - v0.59 (Mar 2023) and v1.0 (July 2023) are as follows:

[Performance benchmarks for v1.0 release](https://github.com/kubevirt/kubevirt/blob/release-1.0/docs/release-v1-perf-scale-benchmarks.md#performance-benchmarks-for-v1-release)

[Scalability benchmarks for v1.0 release](https://github.com/kubevirt/kubevirt/blob/release-1.0/docs/release-v1-perf-scale-benchmarks.md#scalability-benchmarks-for-v1-release)

Publishing these measurements provides the community and end-users visibility into the performance and scalability over multiple releases. In addition, these results help identify the effects of code changes so that community members can diagnose performance problems and regressions.

End-users can use the same tools and techniques SIG-scale uses to analyze performance and scalability in their own deployments. Since performance and scalability are mostly relative to the deployment stack, the same strategies should be used to further contextualize the community’s measurements.

### SIG-storage
SIG-storage is focused on providing persistent storage to KubeVirt VMs and managing that storage throughout the lifecycle of the VM. This begins with provisioning and populating PVCs with bootable images but also includes features such as disk hotplug, snapshots, backup and restore, disaster recovery, and virtual machine export.

For v1.0, SIG-storage delivered the following features: providing a flexible VM export API, enabling persistent SCSI reservation, provisioning VMs from a retained snapshot, and setting out-of-the-box defaults for additional storage provisioners. Another major effort was to implement Volume Populator alternatives to the KubeVirt DataVolume API in order to better leverage platform capabilities. The SIG meets every 2 weeks and welcomes anyone to join us for interesting storage discussions.

### SIG-compute
SIG-compute is focused on the core virtualization functionality of KubeVirt, but also encompasses features that don’t fit well into another SIG. Some examples of SIG-compute’s scope include the lifecycle of VMs, migration, as well as maintenance of the core API.

For v1.0, SIG-compute developed features for memory over-commit. This includes initial support for KSM and FreePageReporting. We added support for persistent vTPM, which makes it much easier to use BitLocker on Windows installs. Additionally, there's now an initial implementation for CPU Hotplug (currently hidden behind a feature gate).

### SIG-network
SIG-network is committed to enhancing and maintaining all aspects of Virtual Machine network connectivity and management in KubeVirt.

For the v1.0 release, we have introduced HotPlug and HotUnplug (as Alpha), which enables users to add and remove VM secondary network interfaces that use bridge binding on a running VM. HotPlug API stabilization and support for SR-IOV interfaces is under development for the next minor release.

### SIG-infra
The effort to simplify the VirtualMachine UX is still ongoing and with the v1.0 release we were able to introduce the v1beta1 version of the instancetype.kubevirt.io API. In the future KubeVirt v1.1.0 release we are aiming to finally graduate the instancetype.kubevirt.io API to v1.

With the new version it is now possible to control the memory overcommit of virtual machines as a percentage within instance types. Resource requirements were added to preferences, which allows users to ensure that requirements of a workload are met. Also several new preference attributes have been added to cover more use cases.

Moreover, virtctl was extended to make use of the new instance type and preference features.

## What next for KubeVirt?
From a development perspective, we will continue to introduce and improve features that make life easier for virtualization users in a manner that is as native to Kubernetes as possible. From a community perspective, we are improving our new contributor experience so that we can continue to grow and help new members learn and be a part of the cloud native ecosystem. In addition, with this milestone we can now shift our attention on becoming a CNCF Graduated project.

