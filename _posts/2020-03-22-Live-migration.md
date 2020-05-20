---
layout: post
author: Pablo Iranzo Gómez
description: KubeVirt leverages Live Migration to support workloads to keep running while nodes can be moved to maintenance, etc Check what is needed to get it working and how it works.
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "Live Migration",
    "node drain",
  ]
comments: true
title: Live Migration in KubeVirt
pub-date: March 22
pub-year: 2020
toc: false
---

<!-- TOC depthFrom:2 depthTo:6 orderedList:false -->

- [Introduction](#introduction)
- [Enabling Live Migration](#enabling-live-migration)
- [Configuring Live Migration](#configuring-live-migration)
- [Performing the Live Migration](#performing-the-live-migration)
  - [Cancelling a Live Migration](#cancelling-a-live-migration)
- [What can go wrong?](#what-can-go-wrong)
- [Node Eviction](#node-eviction)
- [Conclusion](#conclusion)
- [References](#references)

<!-- /TOC -->

## Introduction

This blog post will be explaining on KubeVirt's ability to perform live migration of virtual machines.

> Live Migration is a process during which a running Virtual Machine Instance moves to another compute node while the guest workload continues to run and remain accessible.

The concept of live migration is already well-known among virtualization platforms and enables administrators to keep user workloads running while the servers can be moved to maintenance for any reason that you might think of like:

- Hardware maintenance (physical, firmware upgrades, etc)
- Power management, by moving workloads to a lower number of hypervisors during off-peak hours
- etc

KubeVirt also includes support for virtual machine migration within Kubernetes when enabled.

Keep reading to learn how!

## Enabling Live Migration

To enable live migration we need to enable the `feature-gate` for it by adding `LiveMigration` to the key:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
  labels:
  kubevirt.io: ""
data:
  feature-gates: "LiveMigration"
```

<br>

A current `kubevirt-config` can be edited to append "`LiveMigration`" to an existing configuration:

```sh
kubectl edit configmap kubevirt-config -n kubevirt
```

```yaml
data:
  feature-gates: "DataVolumes,LiveMigration"
```

<br>

## Configuring Live Migration

If we want to alter the defaults for Live-Migration, we can further edit the `kubevirt-config` like:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
  labels:
  kubevirt.io: ""
data:
  feature-gates: "LiveMigration"
  migrations: |-
  parallelMigrationsPerCluster: 5
  parallelOutboundMigrationsPerNode: 2
  bandwidthPerMigration: 64Mi
  completionTimeoutPerGiB: 800
  progressTimeout: 150
```

Parameters are explained in the below table (check the documentation for more details):

| Parameter                           | Default value | Description                                                                   |
| :---------------------------------- | :-----------: | :---------------------------------------------------------------------------- |
| `parallelMigrationsPerCluster`      |       5       | How many migrations might happen at the same time                             |
| `parallelOutboundMigrationsPerNode` |       2       | How many outbound migrations for a particular node                            |
| `bandwidthPerMigration`             |     64Mi      | MiB/s to have the migration limited to, in order to not affect other systems  |
| `completionTimeoutPerGiB`           |      800      | Time for a GiB of data to wait to be completed before aborting the migration. |
| `progressTimeout`                   |      150      | Time to wait for Live Migration to progress in transferring data              |

## Performing the Live Migration

> error "Limitations"
>
> 1. Virtual Machines using PVC must have a `RWX` access mode to be Live-Migrated
> 1. Additionally, pod network binding of bridge interface is not allowed

Live migration is initiated by posting an object `VirtualMachineInstanceMigration` to the cluster, indicating the VM name to migrate, like in the following example:

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: vmi-fedora
```

This will trigger the process for the VM.

> note "NOTE"
>
> When a VM is started, a calculation has been already performed indicating if the VM is live-migratable or not. This information is stored in the `VMI.status.conditions`. Currently, most of the calculation is based on the `Access Mode` for the VMI volumes but can be based on multiple parameters. For example:
>
> ```yaml
> Status:
>   Conditions:
>     Status: True
>     Type: LiveMigratable
>   Migration Method: BlockMigration
> ```

If the VM is Live-Migratable, the request will submit successfully. The status change will be reported under `VMI.status`. Once live migration is complete, a status of `Completed` or `Failed` will be indicated.

> info "Watch out!"
>
> The `Migration Method` field can contain:
>
> - `BlockMigration` : meaning that the disk data is being copied from source to destination
> - `LiveMigration`: meaning that only the memory is copied from source to destination
>
> VMs with block devices located on shared storage backends like the ones provided by [Rook](https://rook.io/) that provide PVCs with ReadWriteMany access have the option to live-migrate only memory contents instead of having to also migrate the block devices.

### Cancelling a Live Migration

If we want to abort the Live Migration, 'Kubernetes-Style', we'll just delete the object we created for triggering it.

In this case, the VM status for migration will report some additional information:

```yaml
Migration State:
  Abort Requested: true
  Abort Status: Succeeded
  Completed: true
  End Timestamp: 2019-03-29T04:02:49Z
  Failed: true
  Migration Config:
    Completion Timeout Per GiB: 800
    Progress Timeout: 150
  Migration UID: 57a693d6-51d7-11e9-b370-525500d15501
  Source Node: node02
  Start Timestamp: 2019-03-29T04:02:47Z
  Target Direct Migration Node Ports:
    39445: 0
    43345: 49152
    44222: 49153
  Target Node: node01
  Target Node Address: 10.128.0.46
  Target Node Domain Detected: true
  Target Pod: virt-launcher-testvmimcbjgw6zrzcmp8wpddvztvzm7x2k6cjbdgktwv8tkq
```

Note that there are some additional fields that indicate that `Abort Requested` happened and in the above example that it has `Succeded`, in this case, the original fields for migration will report as `Completed` (because there's no running migration) and `Failed` set to true.

## What can go wrong?

Live-migration is a complex process that requires transferring data from one 'VM' in one node to another 'VM' into another one, this requires that the activity of the VM being live-migrated to be compatible with the network configuration and throughput so that all the data can be migrated _faster_ than the data is changed at the original VM, this is usually referred to as _converging_.

Some values can be adjusted (check the [table](#configuring-live-migration) for settings that can be tuned), to allow it to succeed but as a trade-off:

- Increasing the number of VMs that can migrate at once, will reduce the available bandwidth.
- Increasing the bandwidth could affect applications running on that node (origin and target).
- Storage migration (check the `Info` note in the [Performing the Live Migration ](#performing-the-live-migration) section on the differences) might also consume bandwidth and resources.

## Node Eviction

Sometimes, a node requires to be put on maintenance and it includes workloads on it, either containers or, in KubeVirt's case, VM's.

It is possible to use **selectors**, for example, move all the virtual machines to another node via `kubectl drain <nodename>`, for example, evicting all KubeVirt VM's from a node can be done via:

```sh
kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher
```

> warning "Reenabling node after eviction"
>
> Once the node has been tainted for eviction, we can use `kubectl uncordon <nodename>` to make it schedulable again.

According to documentation, `--delete-local-data`, `--ignore-daemonsets` and `--force` are required because:

- Pods using `emptyDir` can be deleted because the data is ephemeral.
- VMI will have `DaemonSets` via `virt-handler` so it's safe to proceed.
- VMIs are not owned by a `ReplicaSet` or `DaemonSet`, so kubectl can't guarantee that those are restarted. KubeVirt has its own controllers for it managing VMI, so kubectl shouldn't bother about it.

If we omit the `--pod-selector`, we'll force eviction of all Pods and VM's from a node.

> important "Live Migration eviction"
>
> In order to have VMIs using `LiveMigration` for eviction, we have to add a specific spec in the VMI YAML, so that when the node is tainted with `kubevirt.io/drain:NoSchedule` is added to a node.
>
> ```yaml
> spec:
>   evictionStrategy: LiveMigrate
> ```
>
> From that point, when `kubectl taint nodes <foo> kubevirt.io/drain=draining:NoSchedule` is executed, the migrations will start.

## Conclusion

As a briefing on the above data:

- `LiveMigrate` needs to be enabled on KubeVirt as a feature gate.
- `LiveMigrate` will add status to the VMI object indicating if it's a candidate or not and if so, which mode to use (Block or Live)
  - Based on the storage backend and other conditions, it will enable `LiveMigration` or just `BlockMigration`.

## References

- [Live Migration](https://kubevirt.io/user-guide/#/installation/live-migration?id=live-migration)
- [Node Drain/Eviction](https://kubevirt.io/user-guide/#/installation/node-eviction?id=how-to-evict-all-vms-on-a-node)
- [Rook](https://rook.io/)
