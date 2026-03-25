---
layout: post
author: KubeVirt Maintainers
title: Announcing the release of KubeVirt v1.8
description: With the release of KubeVirt v1.8 we see the community adding some features that align with more traditional virtualization platforms.
navbar_active: 
pub-date: March 25
pub-year: 2026
category: news
tags:
  [
    "KubeVirt",
    "v1.8",
    "release",
    "community",
    "cncf",
    "milestone",
    "party time"
  ]

---
Author: The Kubevirt Community
Release date and time: 25th March 

The [KubeVirt](https://kubevirt.io) Community is happy to announce the release of [v1.8](https://github.com/kubevirt/kubevirt/releases/tag/v1.8.0), which aligns with [Kubernetes v1.35](https://kubernetes.io/blog/2025/12/17/kubernetes-v1-35-release/).

This is the third release since we started our VEP ([Virt Enhancement Proposal](https://github.com/kubevirt/enhancements?tab=readme-ov-file#kubevirt-enhancements-tracking-and-backlog)) process and, after some shaky starts and concerted iterating, we are really starting to see it settle and find a rhythm in the community. We have had a real boom in proposals for this release, and that trend is likely to continue. It's wonderful to see new contributors coming forward with exciting ideas and engage with the project to see them through. 

You can read the full [release notes](https://kubevirt.io/user-guide/release_notes/#v180) in our user-guide, but we have included some highlights in this blog.

For those of you at KubeCon this week, we have a whole bunch of talks, as well as a project kiosk, which we have listed on our [events wiki](https://github.com/kubevirt/community/wiki/Events#upcoming-conferences-with-one-or-more-kubevirt-sessions). 
We are also running our first in-person event: [KubeVirt Summit Live at the Cloud Native Theatre](https://kccnceu2026.sched.com/?searchstring=KubeVirt+Summit&iframe=no) on Thursday March 26th.

### SIG Compute
The Confidential Computing Working Group has introduced improvements to support Intel TDX Attestation in KubeVirt; confidential VMs can now certify that they are running on confidential hardware (Intel TDX currently). 


Another major milestone is the introduction of Hypervisor Abstraction Layer, which enables KubeVirt to integrate multiple hypervisor backends beyond KVM, while still maintaining the current KVM-first behaviour as default.


And because good things happen in threes, we’ve also enabled AI and HPC workloads in VMs to achieve near-native performance with the introduction of PCIe NUMA topology awareness alongside other resource improvements.

### SIG Networking
The `passt` binding has been promoted from a plugin to a core binding. This binding is a significant improvement to an earlier implementation.


Also, you can now live update NAD references without requiring VM restart, allowing you to change a VM's backing network without disrupting the guest.


And we have decoupled KubeVirt from NAD definitions to reduce API calls made by virt-controller, removing a performance bottleneck for VM activation at scale and improving security by removing permissions. Users should be aware that this is a deprecating process and prepare accordingly.

### SIG Storage
The big news on the storage front is two new features: ContainerPath volume and Incremental Backup with CBT.


ContainerPath volumes allow you to map container paths for VM storage and improve portability and configuration options. This provides an escape hatch for cloud provider credential injection patterns.


Incremental Backup with Changed Block Tracking (CBT) leverages QEMU’s and libvirt backup capabilities providing **storage agnostic** incremental VM backups. By capturing only modified data, the solution eliminates reliance on specific CSI drivers, allowing for faster backup windows and a drastically reduced storage footprint. This not only ensures storage freedom but also minimizes cluster network traffic for peak efficiency.
### SIG Scale and Performance

There have been a few test improvements rolled out in SIG Scale and Performance.  First, we have increased the KWOK performance test to 8000 VMIs.  The results have shown the kubevirt control-plane performs well even as VMI counts grow.  On the scale side, when comparing the 100 VMI job to 8000 VMI job, we see some expected memory increases.  The average virt-api memory grows from 140MB to 170MB (+30MB) and average virt-controller memory grows from 65MB to 1400MB (+1335MB).
To determine the memory scaling per Virtual Machine Instance (VMI), we calculate the rate of change on the control-plane in the 100 real VMIs and 8000 KWOK VMIs. This estimates the incremental memory cost for each additional VMI added to the system.

| Component       | Total Memory Increase 100 to 8000 (Δ) | Memory Scale per VMI (MB) | Memory Scale per VMI (KB) |
| --------------- | ------------------------------------- | ------------------------- | ------------------------- |
| virt-api        | 30 MB                                 | 0.0038 MB                 | 3.89 KB                   |
| virt-controller | 1335 MB                               | 0.1690 MB                 | 173.04 KB                 |


We will continue to refine these measurements as they are still estimates and may have some incorrect measurements. Our goal is to eventually publish this along this our comprehensive list of performance and scale benchmarks for each release, which is [here](https://github.com/kubevirt/kubevirt/blob/main/docs/perf-scale-benchmarks.md).


### Thanks!
A lot of work from a huge amount of people go into these releases. Some contributions are small, such as raising a bug or attending our community meeting, and others are massive, like working on a feature or reviewing PRs. Whatever your part: we thank you.

We had a huge amount of features and the next release is looking to be larger still. If you're interested in contributing and being a part of this great project, please check out our [contributing guide](https://kubevirt.io/user-guide/contributing/) and our [community membership guidelines](https://github.com/kubevirt/community/blob/main/membership_policy.md). Reviewing PRs is a great way to learn and gain experience, but it can sometimes be daunting. If you’d like to be involved but aren’t sure, reach out on our Slack or mailing list; we have some wonderful people in the community who can help you find your feet. 

