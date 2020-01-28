---
layout: post
author: Pedro Ibáñez Requena
description: "KubeVirt Intro: Virtual Machine Management on Kubernetes - Steve Gordon & Chandrakanth Jakkidi"
navbar_active: Blogs
category: news
comments: true
title: NA KubeCon 2019 - KubeVirt introduction by Steve Gordon and Chandrakanth Jakkidi
pub-date: January, 29
pub-year: 2019
---


In this session, Steve and Chand provide an introduction to the KubeVirt project, which turns Kubernetes into an 
orchestration engine for not just application containers but virtual machine workloads as well. This provides a 
unified development platform where developers can build, modify, and deploy applications made up of both Application 
Containers as well as Virtual Machines (VM) in a common, shared environment. 

They show how the KubeVirt community is continuously growing and helping with their contributions to the code in
[KubeVirt GitHub repository](https://github.com/kubevirt).

In the session, you will learn more about why KubeVirt exists:
- Growing velocity behind Kubernetes and surrounding ecosystem for new applications.
- Reality that users will be dealing with virtual machine workloads for many years to come.
- Focus on building transition paths for users with workloads that will either never be containerized:
    - Technical reasons (e.g. older operating system or kernel)
    - Business reasons (e.g. time to market, cost of conversion)
- ...or will be decomposed over a longer time horizon.

They also explain the common use cases, how people are using it today:
- To run VM to support new development
    - Build new applications relying on existing VM-based applications and APIs.
    - Leverage Kubernetes-based developer flows while bringing in these VM-based dependencies.
- To run VM to support applications that can’t lift and shift
    - Users with very old applications who are not in a position to change them significantly.
    - Vendors with appliances (customer kernels, custom kmods, optimized workflows to build appliances, ...) they want to bring to the cloud-native ecosystem.
- To run Kubernetes (!)
    - KubeVirt as a Cluster API provider
        - Hard Multi-Tenancy
    - Community provided cloud-provider-kubevirt
- To run Virtual Network Functions (VNFs) and other virtual appliances
    - VNFs in the context of Kubernetes are of continued interest, in parallel to Cloud-Native Network Function exploration.
        - Kubernetes is an attractive target for VNFs.
            - Compute features and management approach is appealing.
            - But: VNFs are hard to containerize!

And also how the project actually works from an architectural perspective and the ideal environment.
![architectural_perspective](/assets/2020-01-29-KubeVirt_Intro-Virtual_Machine_Management_on_Kubernetes/containers_and_vms.png)

And how is the ideal environment with KubeVirt:
![kubevirt_environment](/assets/2020-01-29-KubeVirt_Intro-Virtual_Machine_Management_on_Kubernetes/kubevirt_environment.png)


A walk through the KubeVirt components is also shown:
- virt-api-server: The entry point to KubeVirt for all virtualization related flows and takes care to update the virtualization related custom resource definition (CRD)
- virt-launcher: A VM is inside a POD launched by virt-launcher using Libvirt
![pod_networking](/assets/2020-01-29-KubeVirt_Intro-Virtual_Machine_Management_on_Kubernetes/pod_networking.png)
- virt-controller: Each Object has a corresponding controller
- virt-handler: is a Daemonset that acts as a minion communication to Libvirt via socket
- libvirtd: toolkit to manage virtualization platforms

In the Video, a short demo of the project in action is shown. Eventually, Chand shows how to install KubeVirt and bring up a virtual machine in a short time!

Finally, you will hear about future plans for developing KubeVirt’s capabilities that are emerging from the community. Some hints:
- Better support for deterministic workloads:
    - CPU Pinning○NUMA Topology Alignment
    - IO Thread pinning
- Storage-assisted snapshot and cloning.
- Forensic virtual machine capture
- GPU passthrough
- Policy-based live migration and additional migration modes.
- Hotplugging of CPUs, RAM, disks, and NICs (not necessarily in that order!).

## Video

<iframe width="560" height="315" style="height: 315px" src="https://www.youtube.com/embed/_z5Pjyl0Dq4" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Speakers

[Steve Gordon](https://twitter.com/xsgordon) is currently a Principal Product Manager at Red Hat based in Toronto, Canada.  
Focused on building infrastructure solutions for compute use cases using a spectrum of virtualization, containerization, 
and bare-metal provisioning technologies. 

He got his start in Open Source while building out and managing web-based solutions for the Earth Systems Science Computational 
Centre (ESSCC) at the University of Queensland. After graduating with degrees in Information Technology and Commerce. Stephen took 
a multi-year detour into the wonderful world of the z-Series mainframe while writing new COBOL applications for the Australian Tax Office (ATO).

Stephen then landed at Red Hat where he has grown his knowledge of the infrastructure space working across multiple roles and solutions 
at the intersection of the Linux virtualization stack (KVM, QEMU, Libvirt), OpenStack, and more recently Kubernetes. Now he is working with a 
team attempting to realize a vision for unification of application containers and virtual machines enabled by the KubeVirt project.

Stephen has previously presented on a variety of infrastructure topics at OpenStack Summit, multiple Red Hat Summit, KVM Forum, OpenStack Days Canada, 
OpenStack Silicon Valley, and local meetups.

[Chandrakanth Reddy Jakkidi](https://www.linkedin.com/in/jakkidi-chandrakanth-reddy-149a5920/) is an active OpenSource Contributor. He is involved in CNCF and open infrastructure community projects.
He has contributed to Openstack, Kubernetes projects. Presently an active contributor to Kubevirt Project.
Chandrakanth is having 14+ years experience in Networking ,Virtualization, Cloud, K8S, SDN, NFV, Openstack, Infrastructure Technologies.

He is currently working with F5 Networks as Senior Software Engineer. He previously worked with Cisco Systems, Starent Networks, Emerson/Artesyn Embedded 
Technologies and NXP/Freescale Semiconductors/Intoto Network Security companies. He is a speaker and driven local open source meetups. His present passion 
is towards CNCF projects. In 2018, he was a speaker of 2018 DevOpsDays Event.

## References
- [YouTube Video: KubeVirt Intro: Virtual Machine Management on Kubernetes - Steve Gordon & Chandrakanth Jakkidi](https://www.youtube.com/watch?v=_z5Pjyl0Dq4)
- [Presentation: KubeVirt Intro: Virtual Machine Management on Kubernetes - Steve Gordon & Chandrakanth Jakkidi](https://static.sched.com/hosted_files/kccncna19/70/Introduction_to_KubeVirt-KUBECONNA19.pdf)
- [KubeCon NA 2019 event](https://kccncna19.sched.com/event/VyBC)
