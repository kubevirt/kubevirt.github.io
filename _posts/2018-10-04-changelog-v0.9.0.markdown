---
layout: post
author: kube🤖
description: This article provides information about KubeVirt release v0.9.0 changes
navbar_active: Blogs
datefixme:
category: releases
comments: true
title: KubeVirt v0.9.0
pub-date: October
pub-year: 2018
---


## v0.9.0

Released on: Thu Oct 4 14:42:28 2018 +0200

- CI: NetworkPolicy tests
- CI: Support for an external provider (use a preconfigured cluster for tests)
- Fix virtctl console issues with CRI-O
- Support to initialize empty PVs
- Support for basic CPU pinning
- Support for setting IO Threads
- Support for block volumes
- Move preset logic to mutating webhook
- Introduce basic metrics reporting using prometheus metrics
- Many stabilizing fixes in many places
