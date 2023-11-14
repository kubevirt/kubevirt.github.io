---
layout: post
author: KubeVirt Community
title: Announcing KubeVirt v1.1
description: We are very pleased to announce the release of KubeVirt v1.1!
navbar_active: 
pub-date: November 07
pug-year: 2023
category: news
tags:
  [
    "KubeVirt",
    "v1.1.0",
    "release",
    "community",
    "cncf",
  ]

---

The KubeVirt Community is very pleased to announce the release of KubeVirt v1.1. This comes 17 weeks after our celebrated v1.0 release, and follows the predictable schedule we moved to three releases ago to follow the Kubernetes release cadence.

You can read the full [v1.1 release notes here](https://github.com/kubevirt/kubevirt/releases/tag/v1.1.0), but we’ve asked the KubeVirt SIGs to summarize their largest successes, as well as one of the community members from Arm to list their integration accomplishments for this release. 

## SIG-compute
SIG-compute covers the core functionality of KubeVirt. This includes scheduling VMs, the API, and all KubeVirt operators.

For the v1.1 release, we have added quite a few features. This includes memory hotplug, as a follow up to CPU hotplug, which was part of the 1.0 release. Basic KSM support was already part of KubeVirt, but we have now extended that with more tuning parameters and KubeVirt can also dynamically configure KSM based on system pressure. We’ve added persistent NVRAM support (requires that a VM use UEFI) so that settings are preserved across reboots. 

We’ve also added host-side USB passthrough support, so that USB devices on a cluster node can be made available to workloads. KubeVirt can now automatically apply limits to a VM running in a namespace with quotas. We’ve also added refinements to VM cloning, as well as the ability to create clones using the virtctl CLI tool. And you can now stream guest’s console logs. 

Finally, on the confidential computing front, we now have an API for SEV attestation. 
 
## SIG-infra
SIG-infra takes care of KubeVirt’s own infrastructure, user workloads and other user-focused integrations through automation and the reduction of complexity wherever possible, providing a quality experience for end users.

In this release, two major instance type-related features were added to KubeVirt. The first feature is the deployment of Common InstanceTypes by the virt-operator. This provides users with a useful set of InstanceTypes and Preferences right out of the box and allows them to easily create virtual machines tailored to the needs of their workloads. For now this feature remains behind a feature gate, but in future versions we aim to enable the deployment by default. 

Secondly, the inference of InstanceTypes and Preferences has been enabled by default when creating virtual machines with virtctl. This feature was already present in the previous release, but users still needed to explicitly enable it. Now it is enabled by default, being as transparent as possible so as to not let the creation of virtual machines fail if inference should not be possible. This significantly improves usability, as the command line for creating virtual machines is now even simpler.

## SIG-network
SIG-network is committed to enhancing and maintaining all aspects of Virtual Machine network connectivity and management in KubeVirt.

For the v1.1 release, we have re-designed the interface hot plug/unplug API, while adding hotplug support for SR-IOV interfaces. On top of that, we have added a network binding option allowing the community to extend the KubeVirt network configuration in the pod by injecting custom CNI plugins to configure the networking stack, and a sidecar to configure the libvirt domain. The existing `slirp` network configuration has been extracted from the code and re-designed as one such network binding, and can be used by the community as an example on how to extend KubeVirt bindings.

## SIG-scale
SIG-scale continues to track scale and performance across releases.  The v1.1 testing lanes ran on Kubernetes 1.27 and we observed a slight performance improvement from Kubernetes.  There’s no other notable performance or scale changes in KubeVirt v1.1 as our focus has been on improving our tracking.

#### vmiCreationToRunningSecondsP95
* The gray dotted line in the graph is Feb 1, 2023, denoting release of v0.59
* The blue dotted line in the graph is March 1, 2023, denoting release of v0.60
* The green dotted line in the graph is July 6, 2023, denoting release of v1.0.0
* The red dotted line in the graph is September 6, 2023, denoting change in k8s provider from v1.25 to v1.27

![Alt text](/assets/2023-11-07-Announcing-KubeVirt-v1-1/vmi-p95-Creation-to-Running.png)
![Alt text](/assets/2023-11-07-Announcing-KubeVirt-v1-1/vm-p95-Creation-to-Running.png)


Full v1.1 data source: [https://github.com/kubevirt/kubevirt/blob/main/docs/release-v1-perf-scale-benchmarks.md](https://github.com/kubevirt/kubevirt/blob/main/docs/release-v1-perf-scale-benchmarks.md)


## SIG-storage
SIG-storage is focused on providing persistent storage to KubeVirt VMs and managing that storage throughout the lifecycle of the VM. This begins with provisioning and populating PVCs with bootable images but also includes features such as disk hotplug, snapshots, backup and restore, disaster recovery, and virtual machine export.

For this release we aimed to draw closer to Kubernetes principles when it comes to managing storage artifacts. Introducing CDI volume populators, which is CDI's implementation of importing/uploading/cloning data to PVCs using the `dataSourceRef` field. This follows the Kubernetes way of populating PVCs and enables us to populate PVCs directly without the need for DataVolumes, an important but bespoke object that has served the KubeVirt use case for many years.

Speaking of DataVolumes, they will no longer be garbage collected by default, something that violated a fundamental principle of Kubernetes (even though it was very useful for our use case).

And, finally, we can now use snapshots to store operating system "golden images", to serve as the base image for cloning.

## KubeVirt and Arm
We are excited to announce the successful integration of KubeVirt on Arm64 platforms. Here are some key accomplishments:
1. 	**Building and Compiling**: We have released multi-architecture KubeVirt component images and binaries, while also allowing cross-compiling Arm64 architecture images and binaries on x86_64 platforms.
2. 	**Core Functionality**: Our dedicated efforts have focused on enabling the core functionality of KubeVirt on Arm64 platforms.
3. 	**Testing Integration**: Quality assurance is of paramount importance. We have integrated unit tests and end-to-end tests on Arm64 servers into the pull request (PR) pre-submit process. This guarantees that KubeVirt maintains its reliability and functionality on Arm64.
4. 	**Comprehensive Documentation**: To provide valuable insights into KubeVirt's capabilities on Arm64 platforms, we have compiled extensive documentation. Explore the status of [feature gates](https://kubevirt.io/user-guide/operations/feature_gate_status_on_Arm64/ ) and dive into [device status documentation](https://kubevirt.io/user-guide/virtual_machines/device_status_on_Arm64/).
5.  **Hybrid Cluster Compatibility Preview**: Hybrid x86_64 and Arm64 clusters can work together now as a preview feature. Try it out and provide feedback.

We are thrilled to declare that KubeVirt now offers tier-one support on Arm64 platforms. This milestone represents a culmination of collaborative efforts, unwavering dedication, and a commitment to innovation within the KubeVirt community. KubeVirt is no longer just an option; it has evolved to become a first-class citizen on Arm64 platforms.

## Conclusion
Thank you to everyone in the KubeVirt Community who contributed to this release, whether you pitched in on any of the features listed above, helped out with any of the other features or maintenance improvements listed in our release notes, or made any number of non-code contributions to our website, user guide or meetings. 


