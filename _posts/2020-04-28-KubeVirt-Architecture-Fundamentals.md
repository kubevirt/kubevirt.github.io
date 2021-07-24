---
layout: post
author: David Vossel
description: This blog post outlines the core set of design decisions that shaped KubeVirt into what it is today.
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "design",
    "architecture",
  ]
comments: true
title: KubeVirt Architecture Fundamentals
pub-date: April 28
pub-year: 2020
---

## Placing our Bets

Back in 2017 the KubeVirt architecture team got together and placed their bets on a set of core design principles that became the foundation of what KubeVirt is today. At the time, our decisions broke convention. We chose to take some calculated risks with the understanding that those risks had a real chance of not playing out in our favor.

Luckily, time has proven our bets were well placed. Since those early discussions back in 2017, KubeVirt has grown from a theoretical prototype into a project deployed in production environments with a thriving open source community. While KubeVirt has grown in maturity and sophistication throughout the past few years, the initial set of guidelines established in those early discussions still govern the project’s architecture today.

Those guidelines can be summarized nearly entirely by the following two key decisions.

**Virtual machines run in Pods using the existing container runtimes.** This decision came at a time when other Kubernetes virtualization efforts were creating their own virtualization specific CRI runtimes. We took a bet on our ability to successfully launch virtual machines using existing and future container runtimes within an unadulterated Pod environment.

**Virtual machines are managed using a custom "Kubernetes like" declarative API.** When this decision was made, imperative APIs were the defacto standard for how other platforms managed virtual machines. However, we knew in order to succeed in our mission to deliver a truly cloud-native API managed using existing Kubernetes tooling (like kubectl), we had to adhere fully to the declarative workflow. We took a bet that the lackluster Kubernetes Third Party Resource support (now known as CRDs) would eventually provide the ability to create custom declarative APIs as first class citizens in the cluster.

Let’s dive into these two points a bit and take a look at how these two key decisions permeated throughout our entire design.

## Virtual Machines as Pods

We often pitch KubeVirt by saying something like “KubeVirt allows you to run virtual machines side by side with your container workloads”. However, the reality is **we’re delivering virtual machines as container workloads.** So as far as Kubernetes is concerned, there are no virtual machines, just pods and containers. Fundamentally, KubeVirt virtual machines just look like any other containerized application to the rest of the cluster. It’s our KubeVirt API and control plane that make these containerized virtual machines behave like you’d expect from using other virtual machine management platforms.

The payoff from running virtual machines within a Kubernetes Pod has been huge for us. There’s an entire ecosystem that continues to grow around how to provide pods with access to networks, storage, host devices, cpu, memory, and more. This means every time a problem or feature is added to pods, it’s yet another tool we can use for virtual machines.

Here are a few examples of how pod features meet the needs of virtual machines as well.

**Storage:** Virtual machines need persistent disks. Users should be able to stop a VM, start a VM, and have the data persist. There’s a Kubernetes storage abstraction called a PVC (persistent volume claim) that allows persistent storage to be attached to a pod. This means by placing the virtual machine in a pod, we can use the existing PVC mechanisms of delivering persistent storage to deliver our virtual machine disks.

**Network:** Virtual machines need access to cluster networking. Pods are provided network interfaces that tie directly into the pod network via CNI. We can give a virtual machine running in a pod access to the pod network using the default CNI allocated network interfaces already present in the pod’s environment.

**CPU/Memory:** Users need the ability to assign cpu and memory resources to Virtual machines. We can assign cpu and memory to pods using the resource requests/limits on the pod spec. This means through the use of pod resource requests/limits we are able to assign resources directly to virtual machines as well.

This list goes on and on. As problems are solved for pods, KubeVirt leverages the solution and translates it to the virtual machine equivalent.

## The Declarative KubeVirt Virtualization API

While a KubeVirt virtual machine runs within a pod, that doesn’t change the fact that people working with virtual machines have a different set of expectations for how virtual machines should work compared to how pods are managed.

Here’s the conflict.

Pods are **mortal workloads**. A pod is declared by posting it’s manifest to the cluster, the pod runs once to completion, and that’s it. It’s done.

Virtual machines are **immortal workloads**. A virtual machine doesn’t just run once to completion. Virtual machines have state. They can be started, stopped, and restarted any number of times. Virtual machines have concepts like live migration as well. Furthermore if the node a virtual machine is running on dies, the expectation is for that exact same virtual machine to resurrect on another node maintaining its state.

So, pods run once and virtual machines live forever. How do we reconcile the two? Our solution came from taking a play directly out of the Kubernetes playbook.

The Kubernetes core apis have this concept of layering objects on top of one another through the use of **workload controllers**. For example, the Kubernetes ReplicaSet is a workload controller layered on top of pods. The ReplicaSet controller manages ensuring that there are always ‘x’ number of pod replicas running within the cluster. If a ReplicaSet object declares that 5 pod replicas should be running, but a node dies bringing that total to 4, then the ReplicaSet workload controller manages spinning up a 5th pod in order to meet the declared replica count. The workload controller is always reconciling on the ReplicaSet objects desired state.

Using this established Kubernetes pattern of layering objects on top of one another, we came up with our own virtualization specific API and corresponding workload controller called a **"VirtualMachine"** (big surprise there on the name, right?). Users declare a VirtualMachine object just like they would a pod by posting the VirtualMachine object’s manifest to the cluster. The big difference here that deviates from how pods are managed is that we allow VirtualMachine objects to be declared to exist in different states. For example, you can declare you want to “start” a virtual machine by setting “running: true” on the VirtualMachine object’s spec. Likewise you can declare you want to “stop” a virtual machine by setting “running: false” on the VirtualMachine object’s spec. Behind the scenes, setting the “running” field to true or false results in the workload controller creating or deleting a pod for the virtual machine to live in.

In the end, we essentially created the concept of an **immortal VirtualMachine** by laying our own custom API on top of mortal pods. Our API and controller knows how to resurrect a “stopped” VirtualMachine by constructing a pod with all the right network, storage volumes, cpu, and memory attached to in order to accurately bring the VirtualMachine back to life with the exact same state it stopped with.
