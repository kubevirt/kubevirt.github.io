---
layout: post
author: kubebot
description: This article provides information about Kube Virt release v0.6.0 changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: Kube Virt v0.6.0
pub-date: June
pub-year: 2018
---


## v0.6.0

Released on: Mon Jun 11 09:30:28 2018 +0200

- A range of flakyness reducing test fixes
- Vagrant setup got deprectated
- Updated Docker and CentOS versions
- Add Kubernetes 1.10.3 to test matrix
- A couple of ginkgo concurrency fixes
- A couple of spelling fixes
- A range if infra updates
- Use /dev/kvm if possible, otherwise fallback to emulation
- Add default view/edit/admin RBAC Roles
- Network MTU fixes
- CDRom drives are now read-only
- Secrets can now be correctly referenced on VMs
- Add disk boot ordering
- Add virtctl version
- Add virtctl expose
- Fix virtual machine memory calculations
- Add basic virtual machine Network API
