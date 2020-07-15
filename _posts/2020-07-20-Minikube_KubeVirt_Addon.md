---
layout: post
author: Chris Callegari
description: This blog post describes how to use minikube and the KubeVirt addon
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
    "minikube",
    "addons",
  ]
comments: true
title: Minikube KubeVirt addon
pub-date: July 20
pub-year: 2020
---

## Deploying KubeVirt has just gotten easier!
With the latest release of minikube we can now deploy KubeVirt with a one-liner.


## Deploy minikube
<ol>
  <li>Start minikube.  Since my host is Fedora 32 I will use --driver=kvm2 and
  I will also use --container-runtime=crio<br>
    <code>minikube start --driver=kvm2 --container-runtime=cri-o</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-07-20-Minikube_KubeVirt_Addon/1.png"
        width="115"
        height="72"
        itemprop="thumbnail"
        alt="minikube start">
    </div>
    <br><br>
  </li><li>Check that kubectl client is working correctly<br>
    <code>kubectl cluster-info</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-07-20-Minikube_KubeVirt_Addon/2.png"
        width="115"
        height="11"
        itemprop="thumbnail"
        alt="kubectl cluster-info">
    </div>
    <br><br>
  </li><li>Enable the minikube kubevirt addon<br>
    <code>minikube addons enable kubevirt</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-07-20-Minikube_KubeVirt_Addon/3.png"
        width="115"
        height="10"
        itemprop="thumbnail"
        alt="minikube addons enable kubevirt">
    </div>
    <br><br>
  </li><li>Verify KubeVirt namespace and components<br>
    <code>kubectl get ns; kubectl get all -n kube-system</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-07-20-Minikube_KubeVirt_Addon/4.png"
        width="115"
        height="77"
        itemprop="thumbnail"
        alt="Verify KubeVirt namespace and components">
    </div>
  <br><br>
  </li>
</ol>

### SUCCESS!

From here a user can proceed on to the [Kubevirt Laboratory 1: Use KubeVirt]({% link labs/kubernetes/lab1.md %})

<br>
