---
layout: page
title: KubeVirt Summit 2023
permalink: /summit/
order: 10
---

The third online KubeVirt Summit is coming on March 29-30!

The KubeVirt Summit is a 2-day virtual event to discover,
discuss, hack and learn about managing virtual machines in Kubernetes using
KubeVirt.

This is an opportunity for us to share what we're working on and to promote ideas 
and discussion within the community in real-time. 


## How to attend

[Register for KubeVirt Summit 2023](https://community.cncf.io/events/details/cncf-kubevirt-community-presents-kubevirt-summit-2023/) on the CNCF Community events page. Attendance is free.

## Schedule

Both days were orginally scheduled for 14:00 - 19:00 UTC (10:00–15:00 EDT, 16:00–21:00 CEST).
Due to technical issues Thursday will start will be 13:00 - 19:00 UTC.

### March 29

1400-1425: **Opening remarks and update on KubeVirt’s Road to V1**<br>
Presented by Ryan Hallisey & Fabian Deutsch

Welcome to KubeVirt Summit!

The KubeVirt community will soon create the 59th release for KubeVirt, so let’s talk about what it will take for the next release to be v1.0.0.  In this talk we’ll discuss the upcoming changes in the community to get ready for 1.0 and the timeline.


14:30-1455: **Moving the instance type API towards v1 and streamlining the VM creation process**<br>
Presented by Lee Yarwood & Felix Matouschek

This presentation introduces the current state of the Instance type API (currently v1alpha2) and discusses the future planned improvements as we move towards v1. It will also provide an insight into the latest development advances in KubeVirt aiming to streamline the virtual machine creation process. 

By introducing virtual machine instance types and preferences, KubeVirt gains abstractions for resource sizing, performance and OS support, which allow users to focus on the parameters relevant to their applications. To make instance types and preferences approachable, the command line tools of KubeVirt were extended to enable a user experience on a par with all major hyperscalers.

Attendees of this talk will learn about KubeVirt's new instance types and preferences, how they considerably improve the user experience and how they reduce the maintenance effort of KubeVirt virtual machines.


1500-15:25: **Applying Parallel CI testing on Arm64**<br>
Presented by Haolin Zhang

Currently, we have enabled parallel CI testing on Arm64 server. As the current arm64 server does not support nested virtualization, we use kind platform to run the test. In this section, I will show how we run the CI test in kind environment and what issues we meet when trying to enable the parallel testing.


15:30-15:55: **Squash the flakes! - How does the flake process work? What tools do we have? How do we minimize the impact?**<br>
Presented by Daniel Hiller

Flakes aka tests that don’t behave deterministically, i.e. they fail sometimes and pass sometimes, are an ever recurring problem in software development. This is especially the sad reality when running e2e tests where a lot of components are involved. There are various reasons to why a test can be flaky, however the impact can be as fatal as CI being loaded beyond capacity causing overly long feedback cycles or even users losing trust in CI itself. 

We want to remove flakes as fast as possible to minimize number of retests required. This should lead to shorter time to merge, reduce CI user frustration, improve trust in CI, while at the same time decrease overall load for the CI system.  We start by generating a report of tests that have failed at least once inside a merged PR, meaning that in the end all tests have succeeded, thus flaky tests have been run inside CI. We then look at the report to separate flakes from real issues and forward the flakes to dev teams.  As a result retest numbers have gone down significantly over the last year. 

After attending the session the user will have an idea of what our flake process is, how we exercise it and what the actual outcomes are. 


16:00-16:25: **Scaling KubeVirt reach to legacy virtualization administrators and users by means of KubeVirt-Manager**<br>
Presented by Marcelo Feitoza Parisi

KubeVirt-Manager is an Open Source initiative that plans to democratize KubeVirt usage and scale KubeVirt's reach to legacy virtualization administrators and users, by delivering a simple, effective and friendly Web User Interface for KubeVirt, using technologies like AngularJS, Bootstrap and NoVNC embedded. By implementing a simple Web User Interface, KubeVirt-Manager can effectively eliminate the needs of writing and managing complex Kubernetes YAML files. Containerized Data Importer is also used by KubeVirt-Manager as a backend for Data Volume general management tasks, like provisioning, creating and scaling.


16:30-16:55: **How Killercoda works with KubeVirt**<br>
Presented by Meha Bhalodiya & Adam Gardner

By using KubeVirt in conjunction with Killercoda, users can take advantage of the benefits of virtualization while still utilizing the benefits of Kubernetes. This can provide a powerful and flexible platform for running VMs, and can help to simplify the management of VMs and to improve the performance and security of the platform.  The integration of virtualization technology with Kubernetes allows customers to easily manage and monitor their VMs while taking advantage of the scalability and self-healing capabilities of Kubernetes. With Killercoda, users can create custom virtual networks, use firewalls and load balancers, and even establish VPN connections between VMs and other resources.


17:00-17:50: **DPU Accelerated Networking for KubeVirt Pods**<br>
Presented by Girish Moodalbail

NVIDIA BlueField-2 data processing unit (DPU) delivers a broad set of hardware accelerators to accelerate software-defined networking, storage, and security. In this talk, we are going to focus on SDN and discuss:
1. How have we implemented network virtualization to provide network isolation between KubeVirt Pods 
2. How have we pushed the network virtualization control plane to the DPU,  “bump-in-the-wire” model,  from the Kubernetes Node 
3. How have we implemented multi-homed networks for KubeVirt pods 
4. How have we leveraged the OVN/OVS SDN managed by OVN Kubernetes CNI to achieve the aforementioned features 
5. How have we accelerated the datapath leveraging the DPU’s ASAP2 (Accelerated switching and Packet Processing) technology that has enabled us in achieving high throughput and low latency traffic flows while providing wire speed support for firewall, NATing (SNAT/DNAT), forwarding, QoS, and so on.


18:00-18:25: **Case Study: Upgrading KubeVirt in production**<br>
Presented by Alay Patel

NVIDIA recently upgraded KubeVirt in production from 0.35 to 0.50.  This talk will discuss the challenges that we faced and the lessons learned. This talk will then cover some on-going work in the community (change in release cadence, discussion about api-stability, etc) in order to make upgrades better. 


18:30-1900: **Cloud Native Virtual Dev Environments**<br>
Presented by Hippie Hacker & Jay Tihema

Want to develop in the cloud with your friends? We'll invite you to walk through a demo of using coder with templates using KubeVirt and CAPI to create on demand shared development environments hosted within their own clusters. Something you can host at home or in the cloud!


### March 30

1300-1325: **Update on KubeVirt’s Road to V1**<br>
Presented by Ryan Hallisey & Fabian Deutsch

The KubeVirt community will soon create the 59th release for KubeVirt, so let’s talk about what it will take for the next release to be v1.0.0.  In this talk we’ll discuss the upcoming changes in the community to get ready for 1.0 and the timeline.


13:30-13:55: **Moving the instance type API towards v1 and streamlining the VM creation process**<br>
Presented by Lee Yarwood & Felix Matouschek

This presentation introduces the current state of the Instance type API (currently v1alpha2) and discusses the future planned improvements as we move towards v1. It will also provide an insight into the latest development advances in KubeVirt aiming to streamline the virtual machine creation process.

By introducing virtual machine instance types and preferences, KubeVirt gains abstractions for resource sizing, performance and OS support, which allow users to focus on the parameters relevant to their applications. To make instance types and preferences approachable, the command line tools of KubeVirt were extended to enable a user experience on a par with all major hyperscalers.

Attendees of this talk will learn about KubeVirt's new instance types and preferences, how they considerably improve the user experience and how they reduce the maintenance effort of KubeVirt virtual machines.


14:00-14:25: **The latest in KubeVirt VM exports**<br>
Presented by Maya Rashish

We'll talk about the recently introduced feature for easily exporting VMs and use some recent quality of life improvements that have made it in since the feature was introduced 


14:30-14:55: **High Performance Network Stack for KubeVirt-based Managed Kubernetes**<br>
Presented by Jian Li

With the help of cluster-api-provider-kubevirt (capk) project, it is possible to provide a managed Kubernetes service using KubeVirt as the virtualization infrastructure. A managed Kubernetes service is typically implemented by running Kubernetes inside Virtual Machine for the purpose of provisioning flexibility and TCO reduction. However, running Kubernetes on VM will introduce additional networking overhead which in turn dramatically degrades the overall container networking performance. In this presentation, we will introduce a way to maximize the container networking performance of the managed Kubernetes by applying throughout optimization on both management and workload cluster networking stack using SR-IOV and Network Function offloading technologies. With the proposed approach, we achieved line-rate performance on the container networking.


15:00-15:50: **Image Logistics and Locality in a Global Multi-Cluster Deployment**<br>
Presented by Ryan Beisner &  Tomasz Knopik

"I need my VMI image and I need it now, everywhere, across multiple clusters, around the world."  We’ll define our use cases, discuss the challenges that we’ve experienced, and detail the approaches we have taken to tame the topics of image distribution, and image locality across a global multi-cluster KubeVirt deployment.


16:00-16:25: **KubeVirt VMs all the way down: a custom-sized networking solution for inceptionist clusters**<br>
Presented by Miguel Duarte Barroso & Enrique Lleronte Pastora

Setting up a Kubernetes cluster is a complex process that relies on several components being configured properly. There are multiple distributions and installers helping with this task, each with different default configurations for clusters and infrastructure providers; while these bootstrap providers reduce installation complexity, they don’t address how to manage a cluster day-to-day or a Kubernetes environment long term. You are still missing important features like automated cluster lifecycle management. 

The Cluster API project provides declarative, Kubernetes-style APIs to automate cluster creation, configuration, and management. In this presentation, we will focus on CAP-K: a Cluster API provider implemented using KubeVirt VMs. We will discuss some of the challenging requirements that running nested Kubernetes has. Finally, we will offer a comprehensive solution based on OVN, an SDN solution to provide L2/L3 virtual topologies, ACLs, fully distributed DHCP support, and L3 gateways from logical to physical networks. 

The audience should be familiar with virtualization, and have a basic knowledge of networking. 

The audience will learn the networking requirements of Kubernetes, how to run nested Kubernetes/KubeVirt clusters, understand what are the challenges of isolating traffic on these nested clusters, and finally, how this can be achieved using OVN to implement the networking infrastructure.


16:30-16:55: **High Performance KubeVirt workloads at NVIDIA**<br>
Presented by Piotr Prokop

How NVIDIA ensures predictable low latency for applications running inside KubeVirt VMs. In this talk we will discuss how we configure the network and compute resources for our Virtual Machines and how our latest contributions to KubeVirt and Kubernetes helps us achieve best performance. 


17:00-17:25: **(Tutorial) Don't Knock the Docs: Contributing Documentation to the KubeVirt Project**<br>
Presented by Chandler Wilkerson

Good documentation is one of the key ways for project like KubeVirt to make the leap from sandbox to incubation to graduation. Whether it is filling in the user guide with brand new instructions on a recently merged capability, taking your first steps to becoming a contributor by catching bugs in existing instructions, or submitting a blog post detailing your own KubeVirt end user experience on the main website, the first step is learning how our documentation repositories are laid out, and how to create PRs to merge new or improved content.  Tutorial attendees should expect to learn the basic Git repo structure, how to handle a local container to proof changes to the website, and time permitting, see some of the CI/CD process that governs the actual deployment of the KubeVirt.io webpage and user guide.


17:30-17:55: **KubeVirt SIG-Scale - Latest performance and scalability changes**<br>
Presented by Ryan Hallisey & Alay Patel

The KubeVirt SIG-Scale group meets weekly to discuss performance and scalability for KubeVirt.  This talk will provide updates from the past year, show performance and scale trends observed in the performance CI jobs.


18:00-18:25: **My cluster is running... but does it actually work?**<br>
Presented by Orel Misan

For cases where vanilla KubeVirt does not meet your advanced compute, storage, network, or operational use-cases, you may need to extend its functionality with third party extensions.

With this great flexibility must also come great complexity. After investing much time and effort in configuring your cluster, how do you know it actually works?

In this talk, I will introduce you to checkups: containerized applications that help you verify whether your cluster is working as expected.
I will also demo cluster configuration verification using a checkup. This checkup will verify connectivity between two KubeVirt virtual machines and will measure the network latency. The demo will include how this checkup could be remotely deployed on any cluster, and how its users interact with it from its execution to results retrieval.

Basic understanding of Kubernetes operation is required. Knowledge of KubeVirt or networking is not required.


18:30-18:55: **Lessons learned maintaining KubeVirt - testing**<br>
Presented by Qian Xiao & Natalie Bandel

Upstream KubeVirt has a large set of functional tests that can be leveraged to run in NVIDIA zones to validate KubeVirt condition. NVIDIA extends the upstream community’s test suite to implement different types of tests.  Tests are tweaked/customized from various dimensions(latency, running nodes, etc) to ensure they run successfully in production environments. Using KubeVirt's test suite provides us with a starting point, however the test suite is not fully extensible.  For example, you have to import the entire KubeVirt code base to use some of the functionality.


18:55-19:00: **Closing Remarks**



