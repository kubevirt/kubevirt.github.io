---
layout: post
author: fabiand
description: This is a weekly update from the KubeVirt team.
navbar_active: Blogs
pub-date: November 10
pub-year: 2017
category: updates
comments: true
tags: [release notes, changelog]
---

This is a weekly update from the KubeVirt team.

We are currently driven by

- Being easier to be used on Kubernetes and OpenShift

- Enabling people to contribute

- Node Isolator use-case (more informations soon)

<!-- more -->

Non-code wise this week

- The KVM Forum recording was published: "Running Virtual Machines on
  Kubernetes with libvirt & KVM by Fabian Deutsch & Roman Mohr"
  (<https://www.youtube.com/watch?v=Wh-ejUyuHJ0>)

- Preparing the "virtualization saloon" at KubeCon NA
  (<https://kccncna17.sched.com/event/CU8m>)

This week we achieved to:

- Further improve API documentation (@lukas-bednar)
  (<https://github.com/kubevirt/kubevirt/pull/549>)

- Virtual Machine watchdog device support (@davidvossel)
  (<https://github.com/kubevirt/kubevirt/pull/544>)

- Introduction of virt-dhcp (@vladikr)
  (<https://github.com/kubevirt/kubevirt/pull/525>)

- Less specific manifests
  (<https://github.com/kubevirt/kubevirt/pull/560>) (@fabiand)

In addition to this, we are also working on:

- Addition of more tests to pod networking (@vladikr)
  (<https://github.com/kubevirt/kubevirt/pull/525>)

- Adding helm charts (@cynepco3hahue)
  (<https://github.com/kubernetes/charts/pull/2669>)

- Move manifests to kube-system namespace (@cynepco3hahue)
  (<https://github.com/kubevirt/kubevirt/pull/558>)

- Drafting the publishing of API docs (@lukas-bednar)
  (<https://github.com/kubevirt-incubator/api-reference>)
  (<https://kubevirt.io/api-reference/master/definitions.html>)

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/calendar/embed?src=18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com)

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
