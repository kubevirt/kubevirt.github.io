---
layout: post
author: kubebot
description: This article provides information about Kube Virt release v0.20.0 changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: Kube Virt v0.20.0
pub-date: August
pub-year: 2019
---


## v0.20.0

Released on: Fri Aug 9 16:42:41 2019 +0200

- Containerdisks are now secure and they are not copied anymore on every start.
- Create specific SecurityContextConstraints on OKD instead of using the
- Added clone authorization check for DataVolumes with PVC source
- The sidecar feature is feature-gated now
- Use container image shasums instead of tags for KubeVirt deployments
- Protect control plane components against voluntary evictions with a
- Replaced hardcoded `virtctl` by using the basename of the call, this enables
- Added RNG device to all Fedora VMs in tests and examples (newer kernels might
- The virtual memory is now set to match the memory limit, if memory limit is
- Support nftable for CoreOS
- Added a block-volume flag to the virtctl image-upload command
- Improved virtctl console/vnc data flow
- Removed DataVolumes feature gate in favor of auto-detecting CDI support
- Removed SR-IOV feature gate, it is enabled by default now
- VMI-related metrics have been renamed from `kubevirt_vm_` to `kubevirt_vmi_`
- Added metric to report the VMI count
- Improved integration with HCO by adding a CSV generator tool and modified
- CI Improvements:
