---
layout: post
author: David Vossel
description: This blog post outlines fundamentals around the KubeVirt's approach to installs and updates. 
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
    "operation",
  ]
comments: true
title: KubeVirt Operation Fundamentals
pub-date: April 30
pub-year: 2020
---

## Simplicity Above All Else

In the late 1970s and early 1980s there were two video recording tape formats competing for market domination. The Betamax format was the technically superior option. Yet despite having better audio, video, and build quality, Betamax still eventually lost to the technically inferior VHS format. VHS won because it was “close enough” in terms of quality and drastically reduced the cost to the consumer.

I’ve seen this same pattern play out in the open source world as well. It doesn’t matter how technically superior one project might be over another if no one can operate the thing. The “cost” here is operational complexity. The project people can actually get up and running in 5 minutes as a proof of concept is usually going to win over another project they struggle to stand up for several hours or days.

With KubeVirt, our aim is Betamax for quality and VHS for operational complexity costs. When we have to choose between the two, the option that involves less operational complexity wins 9 out of 10 times.

Essentially, above all else, KubeVirt must be simple to use.

## Installation Made Easy

From my experience, the first (and perhaps the largest) hurdle a user faces when approaching a new project is installation. When the KubeVirt architecture team placed their bet’s on what technical direction to take the project early on, picking a design that was easy to install was a critical component of the decision making process.

As a result, our goal from day one has always been to make installing KubeVirt as simple as posting manifests to the cluster with standard Kubernetes client tooling (like kubectl). No per node package installations, no host level configurations. All KubeVirt components have to be delivered as containers and managed with Kubernetes.

We’ve maintained this simplicity today. Installing KubeVirt v0.27.0 is as simple as…

**Step 1:** posting the KubeVirt operator manifest
```sh
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v0.27.0/kubevirt-operator.yaml
```

**Step 2:** posting the KubeVirt install object, which you can use to define exactly what version you want to install using the KubeVirt operator. In our example here, this custom resource defaults to the release that matches the installed operator.
```sh
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v0.27.0/kubevirt-cr.yaml
```

**Step 3:** and then optionally waiting for the KubeVirt install object’s “Available” condition, which indicates installation has succeeded.
```sh
kubectl -n kubevirt wait kv kubevirt --for condition=Available
```

Maintaining this simplicity played a critical role in our design process early on. At one point we had to make a decision whether to use the existing Kubernetes container runtimes or create our own special virtualization runtime to run in parallel to the cluster’s container runtime. We certainly had more control with our own runtime, but there was no practical way of delivering our own CRI implementation that would be easy to install on existing Kubernetes clusters. The installation would require invasive per node modifications and fall outside of the scope of what we could deliver using Kubernetes manifests alone, so we dropped the idea. Lucky for us, reusing the existing container runtime was both the simplest approach operationally and eventually proved to be the superior approach technically for our use case.

## Zero Downtime Updates

While installation is likely the first hurdle for evaluating a project, how to perform updates quickly becomes the next hurdle before placing a project into production. This is why we created the KubeVirt **virt-operator.**

If you go back and look at the installation steps in the previous section, you’ll notice the first step is to post the virt-operator manifest and the second step is posting a custom resource object. What we’re doing here is bringing up the virt-operator somewhere in the cluster, and then posting a custom resource object representing the KubeVirt install. That second step is telling virt-operator to install KubeVirt. The third step is simply watching our install object to determine when virt-operator has reported the install is complete.

Using our default installation instructions, zero downtime updates are as simple as posting a new virt-operator deployment.

**Step 1.** Update virt-operator from our original install of v0.27.0 to v0.28.0 by applying a new virt-operator manifest.
```sh
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v0.28.0/kubevirt-operator.yaml
```

**Step 2:** Watch the install object to see when the installation completes. Eventually it will report v0.28.0 as the observed version which indicates the update has completed.
```sh
kubectl get kv -o yaml -n kubevirt | grep observedKubeVirtVersion
```

Behind the scenes, virt-operator is coordinating the roll out of all the new KubeVirt components in a way that ensures existing virtual machine workloads are not disrupted.

The KubeVirt community supports and tests the update path between each KubeVirt minor release to ensure workloads remain available both before, during, and after an update has completed. Furthermore, there are a set of functional tests that run on every pull request made to the project that validate the code about to be submitted does not disrupt the update path from the latest KubeVirt release. Our merge process won’t even allow code to enter the code base without first passing these update functional tests on a live cluster.

