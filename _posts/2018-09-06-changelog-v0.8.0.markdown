---
layout: post
author: kubebot
description: This article provides information about Kube Virt release v0.8.0 changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: Kube Virt v0.8.0
pub-date: September
pub-year: 2018
---


## v0.8.0

Released on: Thu Sep 6 14:25:22 2018 +0200

- Support for DataVolume
- Support for a subprotocol for webbrowser terminals
- Support for virtio-rng
- Support disconnected VMs
- Support for setting host model
- Support for host CPU passthrough
- Support setting a vNICs mac and PCI address
- Support for memory over-commit
- Support booting from network devices
- Use less devices by default, aka disable unused ones
- Improved VMI shutdown status
- More logging to improve debugability
- A lot of small fixes, including typos and documentation fixes
- Race detection in tests
- Hook improvements
- Update to use Fedora 28 (includes updates of dependencies like libvirt and
- Move CI to support Kubernetes 1.11
