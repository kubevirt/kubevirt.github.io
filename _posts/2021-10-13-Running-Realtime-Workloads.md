---
layout: post
author: Jordi Gil
description: This blog post details the various enhancements made to improve the performance of real-time workloads in KubeVirt 
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "real-time",
    "NUMA",
    "CPUManager",
  ]
comments: true
title: Running real-time workloads with improved performance
pub-date: October 14
pub-year: 2021
---


## Motivation

It has been possible in KubeVirt for some time already to run a VM running with a RT kernel, however the performance of such workloads never achieved parity against running on top of a bare metal host virtualized. With the availability of NUMA and CPUManager as features in KubeVirt, we were close to a point where we had almost all the ingredients to deliver the [recommended](https://www.libvirt.org/kbase/kvm-realtime.html) tunings in libvirt for achieving the low CPU latency needed for such workloads. We were missing two important settings:
* The ability to configure the VCPUs to run with real-time scheduling policy.
* Lock the VMs huge pages in RAM to prevent swapping. 

## Setting up the Environment
To achieve the lowest latency possible in a given environment, first it needs to be configured to allow its resources to be consumed efficiently. 

### The Cluster
The target node has to be configured to reserve memory for hugepages and the kernel to allow threads to run with real-time scheduling policy. The memory can be reserved as a [kernel boot parameter](https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html) or by changing the kernel's page count at [runtime](https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html). 

The kernel's runtime scheduling limit can be adjusted either by installing a real-time kernel in the node (the recommended option), or changing the kernel's setting `kernel.sched_rt_runtime_us` to equal -1, to allow for unlimited runtime of real-time scheduled threads. This kernel setting defines the time period to be devoted to running real-time threads. KubeVirt will detect if the node has been configured with unlimited runtime and will label the node with `kubevirt.io/realtime` to highlight the capacity of running real-time workloads. Later on we'll come back to this label when we talk about how the workload is scheduled.

It is also recommended tuning the node's BIOS settings for optimal real-time performance is also recommended to achieve even lower CPU latencies. Consult with your hardware provider to obtain the information on how to best tune your equipment.

### KubeVirt
The VM will require to be granted fully dedicated CPUs and be able to use huge pages. These requirements can be achieved in KubeVirt by enabling the feature gates of CPUManager and NUMA in the KubeVirt CR. There is no dedicated feature gate to enable the new real-time optimizations.

## The Manifest
With the cluster configured to provide the dedicated resources for the workload, it's time to review an example of a VM manifest using the optimizations for low CPU latency. The first focus is to reduce the VM's I/O by limiting it's devices to only serial console:

```yaml
spec.domain.devices.autoattachSerialConsole: true
spec.domain.devices.autoattachMemBalloon: false
spec.domain.devices.autoattachGraphicsDevice: false
```

The pod needs to have a guaranteed QoS for its memory and CPU resources, to make sure that the CPU manager will dedicate the requested CPUs to the pod.
```yaml
spec.domain.resources.request.cpu: 2
spec.domain.resources.request.memory: 1Gi
spec.domain.resources.limits.cpu: 2
spec.domain.resources.limits.memory: 1Gi
```

Still on the CPU front, we add the settings to instruct the KVM to give a clear visibility of the host's features to the guest, request the CPU manager in the node to isolate the assigned CPUs and to make sure that the emulator and IO threads in the VM run in their own dedicated VCPU rather than sharing the computational time with the workload. 

```yaml
spec.domain.cpu.model: host-passthrough
spec.domain.cpu.dedicateCpuPlacement: true
spec.domain.cpu.isolateEmulatorThread: true
spec.domain.cpu.ioThreadsPolicy: auto
```

We also request the huge pages size and guaranteed NUMA topology that will pin the CPU and memory resources to a single NUMA node in the host. The Kubernetes scheduler will perform due diligence to schedule the pod in a node with enough free huge pages of the given size.

```yaml
spec.domain.cpu.numa.guestMappingPassthrough: {}
spec.domain.memory.hugepages.pageSize: 1Gi
```

Lastly, we define the new real-time settings to instruct KubeVirt to apply the real-time scheduling policy for the pinned VCPUs and lock the process memory to avoid from being swapped by the host. In this example, we'll configure the workload to only apply the real-time scheduling policy to VCPU 0.

```yaml
spec.domain.cpu.realtime.mask: 0
```

Alternatively, if no `mask` value is specified, all requested CPUs will be configured for real-time scheduling.

```yaml
spec.domain.cpu.realtime: {}
```

The following yaml is a complete manifest including all the settings we just reviewed.

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: fedora-realtime
  name: fedora-realtime
  namespace: poc
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: fedora-realtime
    spec:
      domain:
        devices:
          autoattachSerialConsole: true
          autoattachMemBalloon: false
          autoattachGraphicsDevice: false
          disks:
          - disk:
              bus: virtio
            name: containerdisk      
          - disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 1Gi
            cpu: 2
          limits:
            memory: 1Gi
            cpu: 2
        cpu:
          model: host-passthrough
          dedicatedCpuPlacement: true
          isolateEmulatorThread: true
          ioThreadsPolicy: auto
          features:
            - name: tsc-deadline
              policy: require
          numa:
            guestMappingPassthrough: {}
          realtime:
            mask: "0"
        memory:
          hugepages:
            pageSize: 1Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-realtime-container-disk:20211008_5a22acb18
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
            bootcmd:
              - tuned-adm profile realtime
        name: cloudinitdisk
```

## The Deployment
Because the manifest has enabled the real-time setting, when deployed KubeVirt applies the node label selector so that the Kubernetes scheduler will place the deployment in a node that is able to run threads with real-time scheduling policy (node label `kubevirt.io/realtime`). But there's more, because the manifest also specifies the pod's resource need of dedicated CPUs, KubeVirt will also add the node selector of `cpumanager=true` to guarantee that the pod is able to use the assigned CPUs alone. And finally, the scheduler also takes care of guaranteeing that the target node has sufficient free huge pages of the specified size (1Gi in our example) to satisfy the memory requested. With all these validations checked, the pod is successfully scheduled.  

## Key Takeaways

Being able to run real-time workloads in KubeVirt with lower CPU latency opens new possibilities and expands the use cases where KubeVirt can assist in migrating legacy VMs into the cloud. Real-time workloads are extremely sensitive to the amount of layers between the bare metal and its runtime: the more layers in between, the higher the latency will be. The changes introduced in KubeVirt help reduce such waste and provide lower CPU latencies as the hardware is more efficiently tuned.  