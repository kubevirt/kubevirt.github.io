---
layout: post
author: kube🤖
description: This article provides information about KubeVirt release v0.22.0 changes
navbar_active: Blogs
category: releases
comments: true
title: KubeVirt v0.22.0
pub-date: Oct 10
pub-year: 2019
---


## v0.22.0

Released on: Thu Oct 10 18:55:08 2019 +0200

- Support for Nvidia GPUs and vGPUs exposed by Nvidia Kubevirt Device Plugin.
- VMIs now successfully start if they get a 0xfe prefixed MAC address assigned from the pod network
- Removed dependency on host semanage in SELinux Permissive mode
- Some changes as result of entering the CNCF sandbox (DCO check, FOSSA check, best practice badge)
- Many bug fixes and improvements in several areas
- CI: Introduced a OKD 4 test lane
- CI: Many improved tests, resulting in less flakyness
