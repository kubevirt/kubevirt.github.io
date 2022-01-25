---
layout: post
author: Jed Lejosne
description: KubeVirt now supports using a separate network for live migrations
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "live migration",
    "dedicated network",
  ]
comments: true
title: Dedicated migration network in KubeVirt
pub-date: January 25
pub-year: 2022
---

Since version 0.49, KubeVirt supports live migrating VMIs over a separate network than the one Kubernetes is running on.

Running migrations over a dedicated network is a great way to increase migration bandwidth and reliability.

This article gives an overview of the feature as well as a concrete example. For more technical information, refer to the [KubeVirt documentation](https://kubevirt.io/user-guide/operations/live_migration/#using-a-different-network-for-migrations).

## Hardware configuration

The simplest way to use the feature is to find an unused NIC on every worker node, and to connect them all to the same switch.  

All NICs must have the same name. If they don't, they should be permanently renamed.
The process for renaming NICs varies depending on your operating system, refer to its documentation if you need help.  

Adding servers to the network for services like DHCP or DNS is an option but it is not required.
If a DHCP is running, it is best if it doesn't provide routes to other networks / the internet, to keep the migration network isolated.

## Cluster configuration

The interface between the physical network and KubeVirt is a NetworkAttachmentDefinition (NAD), created in the namespace where KubeVirt is installed.  

The implementation of the NAD is up to the admin, as long as it provides a link to the secondary network.
The admin must also ensure that the NAD is able to provide cluster-wide IPs, either through a physical DHCP, or with another CNI plugin like [whereabouts](https://github.com/k8snetworkplumbingwg/whereabouts)

Important: the subnet used here must be completely distinct from the ones used by the main Kubernetes network, to ensure proper routing.

## Testing

If you just want to test the feature, KubeVirtCI supports the creation of multiple nodes, as well as secondary networks.
All you need is to define the right environment variables before starting the cluster.

See the example below for more info (note that text in the "video" can actually be selected and copy/pasted).

## Example

Here is a quick [example](https://asciinema.org/a/464272) of a dual-node KubeVirtCI cluster running a migration over a secondary network.  

The description of the clip includes more detailed information about the steps involved.
