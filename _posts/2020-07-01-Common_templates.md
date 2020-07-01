---
layout: post
author: Karel Simon
description: This blog post describe basic factors and usage of common-templates
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
    "common-templates",
  ]
comments: true
title: Common-templates
pub-date: July 01
pub-year: 2020
---

## What is a virtual machine template?

The KubeVirt project provides a set of templates (https://github.com/kubevirt/common-templates) to create VMS to handle common usage scenarios. These templates provide a combination of some key factors that could be further customized and processed to have a Virtual Machine object. With common templates you can easily start in a few minutes many VMS with predefined hardware resources (e.g. number of CPUs, requested memory, etc.). 

> warning "Beware"
> common templates work only on OpenShift. Kubernetes doesn’t have support for templates.

## What does a VM template cover?

The key factors which define a template are
* Guest Operating System (OS) This allows to ensure that the emulated hardware is compatible with the guest OS. Furthermore, it allows to maximize the stability of the VM, and allows performance optimizations. Currently common templates support RHEL 6, 7, 8, Centos 6, 7, 8, Fedora 31 and newer, Windows 10, Windows server 2008, 2012 R2, 2016, 2019. The [Ansible playbook](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) [generate-templates.yaml](https://github.com/kubevirt/common-templates/blob/master/generate-templates.yaml) describes all combinations of templates that should be generated.
* Workload type of most virtual machines should be server or desktop to have maximum flexibility; the highperformance workload trades some of this flexibility (ioThreadsPolicy is set to shared) to provide better performances (e.g. IO threads).
* Size (flavor) Defines the amount of resources (CPU, memory) to allocate to the VM. There are 4 sizes: tiny (1 core, 1 Gi memory), small (1 core, 2 Gi memory), medium (1 core, 4 Gi memory), large (2 cores, 8 Gi memory). If these predefined sizes don't suit you, you can create a new template based on common templates via UI (choose `Workloads` in the left panel >> press `Virtualization` >> press `Virtual Machine Templates` >> press `Create Virtual Machine Template` blue button) or CLI (update yaml template and create new template).

<div class="zoom">
  <img
    src="/assets/2020-07-01-Common_templates/create_template.jpg"
    width="100"
    height="60"
    itemprop="thumbnail"
    alt="Create new template" />
</div>

## Accessing the virtual machine templates
If you installed KubeVirt using a [supported method](https://github.com/kubevirt/hyperconverged-cluster-operator), you should find the common templates preinstalled in the cluster. If you want to upgrade the templates, or install them from scratch, you can use one of the [supported releases](https://github.com/kubevirt/common-templates/releases)
There are two ways to install and configure templates:

## Via CLI:

###### To install the templates:
`$ export VERSION="v0.11.2"`

`$ oc create -f https://github.com/kubevirt/common-templates/releases/download/$VERSION/common-templates-$VERSION.yaml`

###### To create VM from template:
`$ oc process rhel8-server-tiny PVCNAME=mydisk NAME=rheltinyvm | oc apply -f -`

###### To start VM from created object:
The created object is now a regular VirtualMachine object and from now it can be controlled by accessing Kubernetes API resources. The preferred way to do this is to use virtctl tool.

`$ virtctl start rheltinyvm`

An alternative way to start the VM is with the oc patch command. Example:

`$ oc patch virtualmachine rheltinyvm --type merge -p '{"spec":{"running":true}}'`

As soon as VM starts, openshift creates a new type of object - `VirtualMachineInstance`. It has a similar name to VirtualMachine.

## Via UI:
The Kubevirt project has an official plugin in OpenShift Cluster Console Web UI. This UI supports the creation of VMS using templates and template features - flavors and workload profiles.

###### To install the templates:

Install OpenShift virtualization operator from `Operators` > `OperatorHub`. The operator-based deployment takes care of installing various components, including the common templates.

<div class="zoom">
  <img
    src="/assets/2020-07-01-Common_templates/operator.jpg"
    width="100"
    height="60"
    itemprop="thumbnail"
    alt="Install operator" />
</div>

###### To create VM from template:
 To create a VM from a template, choose `Workloads` in the left panel >> press `Virtualization` >> press `Create Virtual Machine` blue button >> choose `New with Wizard`. Next, you have to see `Create Virtual Machine` window

<div class="zoom">
  <img
    src="/assets/2020-07-01-Common_templates/create_vm.jpg"
    width="100"
    height="60"
    itemprop="thumbnail"
    alt="Create vm from template" />
</div>

This wizard leads you through the basic setup of vm (like guest operating system, workload, flavor, ...). After vm is created you can start requested vm.

> note "Note"
> after the generation step (UI and CLI), VM objects and template objects have no relationship with each other besides the `vm.kubevirt.io/template: rhel8-server-tiny-v0.10.0` label. This means that changes in templates do not automatically affect VMS, or vice versa.
