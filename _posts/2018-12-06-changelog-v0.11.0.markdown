---
layout: post
author: kubebot
description: This article provides information about KubeVirt release v0.11.0 changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: KubeVirt v0.11.0
pub-date: December
pub-year: 2018
---


## v0.11.0

Released on: Thu Dec 6 10:15:51 2018 +0100

- API: registryDisk got renamed to containreDisk
- CI: User OKD 3.11
- Fix: Tolerate if the PVC has less capacity than expected
- Aligned to use ownerReferences
- Update to libvirt-4.10.0
- Support for VNC on MAC OSX
- Support for network SR-IOV interfaces
- Support for custom DHCP options
- Support for VM restarts via a custom endpoint
- Support for liveness and readiness probes
