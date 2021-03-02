---
layout: page
title: KubeVirt Summit
permalink: /summit/
order: 10
---

The KubeVirt community held its first ever dedicated online event about all
things KubeVirt. The KubeVirt Summit is a 2-day virtual event to discover,
discuss, hack and learn about managing virtual machines in Kubernetes using
KubeVirt.

Everyone with an interest in KubeVirt is welcome to join, users
and contributors alike.

Many thanks to everyone who contributed to the event!

## When

The event took place online during two half-days (5 hours each day):

  - Dates: February 9 and 10, 2021.
  - Time: 14:00 – 19:00 UTC (09:00–14:00 EST, 15:00–20:00 CET)

## Program

The event consisted of 20 sessions with the following schedule (all times in UTC):

| Date   | Time  | Session Title                                                                             |
| ------ | ----- | -------------                                                                             |
| 9/Feb  | 14:00 | [Welcome to the KubeVirt Summit!](#welcome)                                               |
|        | 14:30 | [Automated migration of VMs from VMware or OpenStack to KubeVirt](#automated-migration)   |
|        | 15:00 | [How to avoid merging broken code with automated testing using prow](#prow)               |
|        | 15:30 | [Building great VMs with common templates](#templates)                                    |
|        | 16:00 | [Automating KubeVirt with Tekton Pipelines](#tekton)                                      |
|        | 16:30 | [KubeVirt Data Protection and Forensics Forum](#snapshots)                                |
|        | 17:00 | [Zero Downtime KubeVirt Updates](#upgrades)                                               |
|        | 17:30 | [Introducing Volume Hotplug in KubeVirt](#hotplug)                                        |
|        | 18:00 | [Accelerating VNF and CNF with PCI passthrough and KubeVirt](#pci-passthrough)            |
|        | 18:30 | [Harvester: an Open Source HCI solution built on Kubernetes and KubeVirt](#harvester)     |
| 10/Feb | 14:00 | [KubeVirt Live Migration and SRIOV](#sriov)                                               |
|        | 14:30 | [Moving oVirt and VMware VMs to KubeVirt with VM Import Operator and Forklift](#forklift) |
|        | 15:00 | [KubeVirt opinionated deployment via Hyperconverged Cluster Operator](#hco)               |
|        | 15:30 | [Privilege dropping, one capability at a time](#capabilities)                             |
|        | 16:00 | [Introducing the new KubeVirt driver for Ansible Molecule](#molecule)                     |
|        | 16:30 | [Virtual Machine Batch API](#batch-api)                                                   |
|        | 17:00 | [CPU Pinning with custom policies](#cpu-pinning)                                          |
|        | 17:30 | [The Road to Version 1](#road-v1)                                                         |
|        | 18:00 | [Moving a Visual Effects Studio to the cloud with Kubernetes and KubeVirt](#vfx)          |
|        | 18:30 | [Office Hours: Q&A with KubeVirt maintainers](#office-hours)                              |

## Session details

Here is a list of all the sessions with a short abstract, presenter information and links to the session's recording and slides.

<a name="welcome"></a>
### Welcome to the KubeVirt Summit! Introduction and history

[Recording](https://youtu.be/BX0k5jnyNag) / [Slides](https://drive.google.com/file/d/1CCnemQ1CntxskcOlgkTieFb2omR-GQ_I/view)

In the first session of the KubeVirt Summit, Fabian Deutsch ([@dummdida](https://twitter.com/dummdida)) talks about the project's history.

<a name="automated-migration"></a>
### Automated Migration of VMs from VMware or Openstack to KubeVirt

[Recording](https://youtu.be/2Fm8IJ7gyRg) / [Slides](https://drive.google.com/file/d/1gOteQvEwU2vR4dPAxNLC0iAZ0UwlUcYE/view?usp=sharing)

KubeVirt opens scenarios for a Kubernetes based infrastructure that can handle both VMs and containers. Wouldn't it be great to just automatically move all your Virtual Machines from legacy environments and consolidate your whole infrastructure around Kubernetes and KubeVirt?

Coriolis performs automated migrations among most common clouds and virtualization solutions, like VMware, OpenStack, AWS, Azure, AzureStack, OCI, Hyper-V and now also KubeVirt.

During this session we will perform a live demo showing how to migrate a VM from VMware vSphere to KubeVirt and a separate demo showing the migration of a VM from OpenStack to KubeVirt.

Presenters:
  - Alessandro Pilotti, CEO/CTO, Cloudbase Solutions, [@cloudbaseit](https://twitter.com/cloudbaseit), <https://github.com/alexpilotti/>
  - Gabriel Samfira, Cloud Architect, Cloudbase Solutions, [@gabriel_samfira](https://twitter.com/gabriel_samfira), <https://github.com/gabriel-samfira>

<a name="prow"></a>
### Avoid merging broken code with Prow

[Recording](https://youtu.be/4JV7YJbini0) / [Slides](https://drive.google.com/file/d/14A-pKmSwMZCDghATnOTHcAkt84TPu_AD/view?usp=sharing)

This session is about creation of prow jobs in general. Prow is a Kubernetes based CI/CD system.

We cover what is a prow job, what job types are available, how to configure job triggers, testing jobs: requirements, obstacles and pitfalls configurations for merge gating other usages of jobs (publishing, bumping, ...).

Attendants will be able to know what job types are available, which one to use for a specific problem and how to verify their job works on their machine (TM) before creating a PR.

Presenter: Daniel Hiller, Senior Software Engineer OpenShift Virtualization, Red Hat. [@dhill3r](https://twitter.com/dhill3r), <https://github.com/dhiller>

<a name="templates"></a>
### Building great VMs with common templates

[Recording](https://youtu.be/C0zTKrMSQXE)

Common templates are covering most of the nowadays operating systems. Users can easily create e.g. Windows VMs, without complicated settings. 

The presentation covers:
- What are common templates
- Which operating systems are supported
- How common templates work
- How to use them

Attendants will be able to know what are common templates and how to use them.

Presenter: Karel Simon, Software Engineer, Red Hat

<a name="tekton"></a>
### Automating KubeVirt with Tekton Pipelines

[Recording](https://youtu.be/ZA4fN_ogpY0) / [Slides](https://drive.google.com/file/d/1baGeO-iPsI2HPzS8pq1b4My3hRQDSfw5/view?usp=sharing)

This talk introduces a new effort to bring KubeVirt specific tasks to Tekton
Pipelines (CI/CD-style pipelines on k8s).  The goal of this project is to have
tasks for managing VMs and running virtualized workloads as part of the
pipelines flow.

The speaker will showcase what pipelines you can build at the moment, and what
are the plans for the future.

Presenter: Filip Křepinský, Senior Software Engineer, Red Hat, <https://github.com/suomiy>

<a name="snapshots"></a>
### KubeVirt data protection and forensics forum

[Recording](https://youtu.be/qRw2cLVqJ3c) / [Slides](https://drive.google.com/file/d/1QQijYPFVQx7Ki2VVaQtNObSjJdeno0iS/view?usp=sharing)

Let's get together to discuss plans/ideas to extend KubeVirt's data protection and forensics functionality.

Presenters:
  - Michael Henriksen, Red Hat, <https://github.com/mhenriks>
  - Ryan Hallisey, NVIDIA, [@rthallisey](https://twitter.com/rthallisey), <https://github.com/rthallisey>

<a name="upgrades"></a>
### Zero downtime KubeVirt updates

[Recording](https://youtu.be/UZCFmrVFSz8) / [Slides](https://drive.google.com/file/d/1MYPo8rp1SGPNJnVhothDBFYccxxLtX65/view?usp=sharing)

KubeVirt has a very precise and resilient method for ensuring zero downtime updates occur.

In this session I'll cover the general strategy behind how we approach updating KubeVirt from a developer's perspective as well as discuss future improvements to our update process.

Attendees will come away with an understanding of how KubeVirt's update process has been designed, how it is tested, and what future enhancements are coming soon.

Presenter: David Vossel, Senior Principal Software Engineer, Red Hat, <https://github.com/davidvossel>

<a name="hotplug"></a>
### Introducing Volume Hotplug in KubeVirt

[Recording](https://youtu.be/4OxcqF4Lmh0) / [Slides](https://drive.google.com/file/d/18-BpnpAwDbmvWtJ63_tWTzF98XDTFVM7/view?usp=sharing)

Introduction into the current state of volume hotplugging in KubeVirt, what is possible, what is not possible and what are the challenges.

Presenter: Alexander Wels, Principal Software Engineer, Red Hat

<a name="pci-passthrough"></a>
### Accelerating VNF and CNF with PCI passthrough and KubeVirt

[Recording](https://youtu.be/PJ4D2NqMO2A) / [Slides](https://drive.google.com/file/d/17QJDZQj8zkoyCLjKwDz97vz4Wjw8CH3s/view?usp=sharing)

This session introduces PCI device passthrough to containers and VMs managed by KubeVirt.

An overview of PCI passthrough and the Generic Device API is provided, illustrated with a specific practical use case that uses Intel QAT to accelerate VNF/CNF in edge computing.

Presenters:
  - Vladik Romanovsky, Principal Software Engineer, Red Hat
  - Le Yao, Intel SSE/CSE

<a name="harvester"></a>
### Harvester: an OSS HCI solution built on Kubernetes and KubeVirt

[Recording](https://youtu.be/Kp_xs4bfUXI) / [Slides](https://drive.google.com/file/d/1DeCgnDF4aFFMq3tVeWtrO5LuxbjMYPo2/view?usp=sharing)

Project Harvester is a new open source alternative to traditional proprietary hyperconverged infrastructure software. It is built on top of cutting-edge open source technologies including Kubernetes, KubeVirt and Longhorn.

In this talk, we will talk about why we decide to build Harvester, how did we integrated with KubeVirt, and the lessons we've learnt along the way. We will also have a demo of current release of Harvester by the end of session.

Presenter: Sheng Yang: Senior Engineering Manager, SUSE, [@yasker](https://twitter.com/yasker), <https://github.com/yasker>

<a name="sriov"></a>
### Kubevirt Live migration and SRIOV

[Recording](https://youtu.be/PxsVU95vLp8) / [Slides](https://drive.google.com/file/d/1DeCgnDF4aFFMq3tVeWtrO5LuxbjMYPo2/view?usp=sharing)

KubeVirt Live Migration now supports VM's connected to SRIOV NIC's.

On virtualized environments, Live Migration is a tool you want to have in your toolbox especially on production. It enables you to improve your services availability and reduce the recovery time drastically. 

In this session we will discuss why and how to use this feature for VM's with SRIOV NIC's.

Presenter: Or Mergi, Software Engineer, Red Hat, <https://github.com/ormergi>

<a name="forklift"></a>
### Moving oVirt and VMware VMs to KubeVirt with VM Import Operator and Forklift

[Recording](https://youtu.be/S7hVcv2Fu6I) / [Slides](https://drive.google.com/file/d/1JS0xugQvXB_yXsISbLQlnjhRCq85dLTR/view?usp=sharing)

VM Import Operator (VMIO) allows Kubernetes administrators to easily import their oVirt- and VMware- managed virtual machines to KubeVirt.

Konveyor's Forklift is a project that leverages VMIO to propose a user interface for large scale migrations, introducing the concept of migration plan and implementing inventory and validation services.

In this talk, the speakers will explain the design of the Virtual Machine Import Operator and how it can be used to import virtual machines to KubeVirt. Afterwards the speakers will show how Forklift uses VMIO to deliver better user experience while importing virtual machines to KubeVirt.

The attendees will:

- learn how VM Import Operator works
- see an oVirt virtual machine import to Kubernetes (KubeVirt) with VMIO
- see VMware virtual machines import to Kubernetes (KubeVirt) with Forklift
- know how to import their VMware or oVirt workloads to Kubernetes with VMIO or Forklift

Presenters:
- Jakub Dzon, Senior Software Engineer, Red Hat
- Fabien Dupont, Senior Principal Engineer & Engineering Manager, Red Hat

References:
- [VM Import Operator](https://github.com/kubevirt/vm-import-operator) (VMIO).
- Konveyor's [Forklift](https://docs.konveyor.io/).

<a name="hco"></a>
### KubeVirt opinionated deployment via Hyperconverged Cluster Operator

[Recording](https://youtu.be/6Jxbt1SzLRE) / [Slides](https://drive.google.com/file/d/1zO3B0IWe4jxJlOrHBu5I4nvt6pvvqHNc/view?usp=sharing)

How deploy KubeVirt and several adjacent operators with ease?

The HyperConverged Cluster operator (HCO) is a unified operator deploying and controlling KubeVirt and several adjacent operators:

- Containerized Data Importer
- Scheduling, Scale and Performance
- Cluster Network Addons
- Node Maintenance

The purpose of HCO is to ease the deployment, upgrade, monitoring and configuration of an opinionated version of the KubeVirt cluster.

The Hyperconverged Cluster Operator can be installed on bare metal server clusters in a matter of minutes, even from a GUI, without requiring a deep knowledge of Kubernetes internals.

An attendee will learn:

- how to deploy and maintain a KubeVirt cluster with the Hyperconverged Cluster Operator
- a [demo](https://youtu.be/tHPHfL5PzGM​)
- ongoing development and how to contribute

Presenters:
- Nahshon Unna-Tsametet, Senior Software Engineer, Red Hat, <https://github.com/nunnatsa​>
- Oren Cohen, Software Engineer, Red Hat, <https://github.com/orenc1​>

References:
- [HyperConverged Cluster operator](https://github.com/kubevirt/hyperconverged-cluster-operator) (HCO).

<a name="capabilities"></a>
### Privilege dropping, one capability at a time

[Recording](https://youtu.be/7qVcDraf_DI) / [Slides](https://drive.google.com/file/d/1m-oRtZYiMEasr6ICSDc3ShHGEqm0IFsM/view?usp=sharing)

KubeVirt's architecture is composed of two main components: virt-handler, a trusted DaemonSet, running in each node, which operates as the virtualization agent, and virt-launcher, an untrusted Kubernetes pod encapsulating a single libvirt + qemu process.

To reduce the attack surface of the overall solution, the untrusted virt-launcher component should run with as little linux capabilities as possible.

The goal of this talk is to explain the journey to get there, and the steps taken to drop CAPNETADMIN, and CAPNETRAW from the untrusted component.

This talk will encompass changes in KubeVirt and Libvirt, and requires some general prior information about networking (dhcp / L2 networking).

Presenter: Miguel Duarte Barroso, Software Developer, Red Hat

<a name="molecule"></a>
### Introducing the new KubeVirt driver for Ansible Molecule

[Recording](https://youtu.be/oCk6hzk7lAM) / [Slides](https://drive.google.com/file/d/1jvoat_XT16YX5wwA7AwBMo3p3vs2r2xF/view?usp=sharing)

Molecule is a well known test framework for Ansible. But when you run your Molecule test in Kubernetes, no real good solution exists. I'm working on creating new Molecule driver for KubeVirt to find a better approach and get a 100% pure Kubernetes solution.

In this session I will introduce quickly why it may be better than actual drivers, how it works, and make a demo.

Presenter: Joël Séguillon, Senior DevOps Consultant in mission at [www.ateme.com](https://www.ateme.com) - <https://github.com/jseguillon> ([LinkedIn](https://www.linkedin.com/in/jo%C3%ABl-s%C3%A9guillon-91a55814/))

<a name="batch-api"></a>
### Virtual Machine Batch API

[Recording](https://youtu.be/BbzFMcksMlU) / [Slides](https://drive.google.com/file/d/1z6t70wiaF6WukOTauY0ZPiAF33J6d6oT/view?usp=sharing)

KubeVirt extends the Kubernetes ReplicaSets API to provide Virtual Machines with similar functionality and the same can be done with Kubernetes Jobs. In order to bulk schedule VirtualMachines, an admin could use a VirtualMachine Batch API, a VirtualMachineJob, to launch many VirtualMachines from a single API call.

In this session, we’d like to share ideas, discuss use cases, and consider possible solutions to bulk Virtual Machine scheduling.

Presenters:
- Huy Pham, NVIDIA. <https://github.com/huypham21>
- Ryan Hallisey, NVIDIA, [@rthallisey](https://twitter.com/rthallisey), <https://github.com/rthallisey>

<a name="cpu-pinning"></a>
### CPU Pinning with custom policies

[Recording](https://youtu.be/xSMFQR_Uh1M) / [Slides](https://drive.google.com/file/d/16Wy8s-uCr_B6GdQgWBB1_EIX2awUTFDu/view?usp=sharing)

KubeVirt supports CPU pinning via the Kubernetes CPU Manager. However there are a few gaps with achieving CPU pinning only via CPU Manager: It supports only static policy and doesn’t allow for custom pinning. It supports only Guaranteed QoS class.

The insistence by CPU Manager to keep a shared pool means that it is impossible to overcommit in a way that allows all CPUs to be bound to guest CPUs. It provides a best-effort allocation of CPUs belonging to a socket and physical core. In such cases it is susceptible to corner cases and might lead to fragmentation. That is, Kubernetes keeps us from deploying VMs as densely as we can without Kubernetes.

An important requirement for us is to do away with the shared pool and let kubelet and containers that do not require dedicated placement to use any CPU, just as system processes do. Moreover, system services such as the container runtime and the kubelet itself can continue to run on these exclusive CPUs. The exclusivity offered by the CPU Manager only extends to other pods.

In this session we’d like to discuss the workarounds we use for supporting a custom CPU pinning using a dedicated CPU device plugin and integrating it with KubeVirt and discuss use cases.

Presenters:
- Sowmya Seetharaman, NVIDIA, <https://github.com/sseetharaman6>
- Dhanya Bhat, NVIDIA, <https://github.com/dbbhat>

<a name="road-v1"></a>
### The Road to Version 1

[Recording](https://youtu.be/Qcci8U1J05w)

A few months ago the KubeVirt community started to discuss what would be the requirements that KubeVirt should meet in order to release KubeVirt Version 1.0.

This session aims to:

- Provide a recap of the discussion so far
- Review any relevant updates since the last time the plan was discussed
- Collect additional feedback / elements for discussion
- Propose the next steps to take

In summary, this session is another step in the journey towards the release of KubeVirt Version 1.

Session lead: David Vossel, Senior Principal Software Engineer, Red Hat

<a name="vfx"></a>
### Moving a Visual Effects Studio to the cloud with Kubernetes and KubeVirt

[Recording](https://youtu.be/me25mlhgERI)

As the rapid transition to remote work happened, VFX studios and designers used to beefy workstations, on-site storage clusters and high performance networking have had to scramble to make those resources available to people at home.

This presentation details how a VFX studio with 60 designers transitioned from a fully on-premise environment to complete cloud workflow. Combining KubeVirt powered Virtual Workstations with render nodes and storage running natively in Kubernetes provided a solution that beat expectations. Being able to manage all components via the same Kubernetes API allowed for a quick integration into existing systems.

We will be discussing our experience integrating KubeVirt under a strict deadline while leveraging bleeding edge features such as Virtio-FS.

Presenter: Peter Salanki, Director of Engineering, CoreWeave, Inc, <https://github.com/salanki>

<a name="office-hours"></a>
### Office Hours: Q&A with KubeVirt maintainers

[Recording](https://youtu.be/cWNxJHiLPek)

Our final session is an opportunity for you to ask all your KubeVirt questions, whether they're about the project, or they are about using KubeVirt in production. Maintainers and experts will be on hand.

Panelists:
- David Vossel, Senior Principal Software Engineer, Red Hat
- Adam Litke, Engineering Manager, Red Hat
- Petr Horacek, Engineering Manager, Red Hat

## What's next?

Keep the conversations going through the [mailing list](https://groups.google.com/forum/#!forum/kubevirt-dev) or the [#virtualization Slack channel](https://kubernetes.slack.com/archives/C8ED7RKFE) in Kubernetes Slack (register [here](https://slack.k8s.io/) if needed)!

## Sponsors

The KubeVirt Summit is sponsored by the [CNCF](https://cncf.io/)
