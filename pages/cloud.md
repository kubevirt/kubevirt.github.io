---
layout: labs
title: Easy installation on Cloud Providers
tags: [gcp, aws]
permalink: pages/cloud
lab: kubernetes
tags: [gcp, aws, alicloud, azure, amazon, google, quickstart, tutorial]
order: 1
---

# Easy install using Cloud Providers

## Introduction

> info ""
> KubeVirt has been tested on GCP and AWS providers, this approach is intended for demonstration purposes similar to the environments for [Kind]({% link pages/quickstart_kind.md %}) and [Minikube]({% link pages/quickstart_minikube.md %}) and of course the [Katacoda scenarios](https://katacoda.com/kubevirt).

KubeVirt can be tested on external Cloud Providers like AWS, Azure, GCP, AliCloud, and others.

> warning ""
> Note this setup **is not meant for production**, it is meant to give you a quick taste of KubeVirt's functionality.

## Step1: Create a new machine

Check Kubernetes.io guide for each cloud provider to match your use case:

> error ""
> Usage of Cloud Providers like GCP or AWS (or others) might have additional costs or require trial account and setup prior to be able to run those instructions, like for example, creating a default keypair or others.

| Provider | Link                                                                             |
| -------- | -------------------------------------------------------------------------------- |
| AliCloud | <https://kubernetes.io/docs/setup/production-environment/turnkey/alibaba-cloud/> |
| AWS      | <https://kubernetes.io/docs/setup/production-environment/turnkey/aws/>           |
| Azure    | <https://kubernetes.io/docs/setup/production-environment/turnkey/azure/>         |
| GCP      | <https://kubernetes.io/docs/setup/production-environment/turnkey/gce/>           |
| Others   | <https://kubernetes.io/docs/setup/production-environment/turnkey/>               |

> info ""
> Create a disk of 30Gb at least.

After following the instructions provided by <Kubernetes.io>, `kubectl` can be used to manage the cluster.

## Step2: Go to the labs!

At this point you can follow with the [Labs in this website]({% link pages/labs.md %}) to deploy and experiment with KubeVirt.
