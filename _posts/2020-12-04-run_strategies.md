---
layout: post
author: Stu Gott
description: This blog post outlines the various RunStrategies available to VMs
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
  ]
comments: true
title: High Availability -- RunStrategies for Virtual Machines
pub-date: December 04
pub-year: 2020
---

# Why Isn't My VM Running?

There's been a longstanding point of confusion in KubeVirt's API. One that was raised yet again a few times recently. The confusion stems from the "Running" field of the VM spec. Language has meaning. It's natural to take it at face value that "Running" means "Running", right? Well, not so fast.

# Spec vs Status

KubeVirt objects follow Kubernetes convention in that they generally have Spec and Status stanzas. The Spec is user configurable and allows the user to indicate the desired state of the cluster in a declarative manner. Meanwhile status sections are not user configurable and reflect the actual state of things in the cluster. In short, users edit the Spec and controllers edit the Status.

So back to the Running field. In this case the Running field is in the VM's Spec. In other words it's the user's intent that the VM is running. It doesn't reflect the actual running state of the VM.

# RunStrategy

There's a flip side to the above, equally as confusing: "Running" isn't always what the user wants. If a user logs into a VM and shuts it down from inside the guest, KubeVirt will dutifully re-spawn it! There certainly exist high availability use cases where that's exactly the correct reaction, but in most cases that's just plain confusing. Shutdown is not restart!

We decided to tackle both issues at the same time--by deprecating the "Running" field. As already noted, we could have picked a better name to begin with. By using the name "RunStrategy", it should hopefully be more clear to the end user that they're asking for a state, which is of course completely separate from what the system can actually provide. While RunStrategy helps address the nomenclature confusion, it also happens to be an enumerated value. Since Running is a boolean, it can only be true or false. We're now able to create more meaningful states to accommodate different use cases.

## Four RunStrategies currently exist:

* Always: If a VM is stopped for any reason, a new instance will be spawned.
* RerunOnFailure: If a VM ends execution in an error state, a new instance will be spawned. This addressed the second concern listed above. If a user halts a VM manually a new instance will not be spawned.
* Manual: This is exactly what it means. KubeVirt will neither attempt to start or stop a VM. In order to change state, the user must invoke start/stop/restart from the API. There exist convenience functions in the virtctl command line client as well.
* Halted: The VM will be stopped if it's running, and will remain off.

An example using the RerunOnFailure RunStrategy was presented in [KubeVirt VM Image Usage Patterns]({%post_url 2020-05-12-KubeVirt-VM-Image-Usage-Patterns %})

# High Availability

No discussion of RunStrategies is complete without mentioning High Availability. After all, the implication behind the RerunOnFailure and Always RunStrategies is that your VM should always be available. For the most part this is completely true, but there's one important scenario where there's a gap to be aware of: if a node fails completely, e.g. loss of networking or power. Without some means of automatic detection that the node is no longer active, KubeVirt won't know that the VM has failed. On OpenShift clusters installed using Installer Provisioned Infrastructure (IPI) with MachineHealthCheck enabled can detect failed nodes and reschedule workloads running there.

Mode information on IPI and MHC can be found here:

[Installer Provisioned Infrastructure](https://docs.openshift.com/container-platform/4.6/installing/installing_bare_metal_ipi/ipi-install-overview.html#ipi-install-overview)
[Machine Health Check](https://docs.openshift.com/container-platform/4.6/machine_management/deploying-machine-health-checks.html)
