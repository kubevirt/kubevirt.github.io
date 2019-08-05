---
layout: post
author: kubebot
description: This article provides information about Kube Virt release v0.19.0 changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: Kube Virt v0.19.0
pub-date: July
pub-year: 2019
---


## v0.19.0

Released on: Fri Jul 5 12:52:16 2019 +0200

- Fixes when run on kind
- Fixes for sub-resource RBAC
- Limit pod network interface bindings
- Many additional bug fixes in many areas
- Additional testcases for updates, disk types, live migration with NFS
- Additional testcases for memory over-commit, block storage, cpu manager,
- Improvements around HyperV
- Improved error handling for runStartegies
- Improved update procedure
- Improved network metrics reporting (packets and errors)
- Improved guest overhead calculation
- Improved SR-IOV testsuite
- Support for live migration auto-converge
- Support for config-drive disks
- Support for setting a pullPolicy con containerDisks
- Support for unprivileged VMs when using SR-IOV
- Introduction of a project security policy
