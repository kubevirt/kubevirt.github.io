---
layout: post
author: kube🤖
description: This article provides information about KubeVirt release v0.7.0 changes
navbar_active: Blogs
category: releases
comments: true
title: KubeVirt v0.7.0
pub-date: Jul 04
pub-year: 2018
---


## v0.7.0

Released on: Wed Jul 4 17:41:33 2018 +0200

- CI: Move test storage to hostPath
- CI: Add support for Kubernetes 1.10.4
- CI: Improved network tests for multiple-interfaces
- CI: Drop Origin 3.9 support
- CI: Add test for testing templates on Origin
- VM to VMI rename
- VM affinity and anti-affinity
- Add awareness for multiple networks
- Add hugepage support
- Add device-plugin based kvm
- Add support for setting the network interface model
- Add (basic and inital) Kubernetes compatible networking approach (SLIRP)
- Add role aggregation for our roles
- Add support for setting a disks serial number
- Add support for specyfing the CPU model
- Add support for setting an network intefraces MAC address
- Relocate binaries for FHS conformance
- Logging improvements
- Template fixes
- Fix OpenShift CRD validation
- virtctl: Improve vnc logging improvements
- virtctl: Add expose
- virtctl: Use PATCH instead of PUT
