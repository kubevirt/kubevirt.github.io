---
layout: post
author: Felix Matouschek, Andrew Block
title: Managing KubeVirt VMs with Ansible
description: This post explains how to manage KubeVirt VMs with the kubevirt.core Ansible collection.
navbar_active: Blogs
pub-date: September 5
pub-year: 2023
category: news
tags:
  [
    "Kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "Ansible",
    "ansible collection",
    "kubevirt.core",
    "iac"
  ]
comments: true
---

## Introduction

Infrastructure teams managing virtual machines (VMs) and the end users of these systems make use of a variety of tools as part of their day-to-day world. One such tool that is shared amongst these two groups is Ansible, an agentless automation tool for the enterprise. To simplify both the adoption and usage of KubeVirt as well as to integrate seamlessly into existing workflows, the KubeVirt community is excited to introduce the release of the first version of the KubeVirt collection for [Ansible](https://docs.ansible.com/ansible/latest/index.html), called `kubevirt.core`, which includes a number of tools that you do not want to miss.

This article will review some of the features and their use associated with this initial release.

Note: There is also a video version of this blog, which can be found on the [KubeVirt YouTube channel](https://youtu.be/GVROaPgJD_8).

## Motivation

Before diving into the featureset of the collection itself, let's review why the collection was created in the first place.

While adopting KubeVirt and Kubernetes has the potential to disrupt the workflows of teams that typically manage VM infrastructure, including the end users themselves, many of the same paradigms remain:

- Kubernetes and the resources associated with KubeVirt can be represented in a declarative fashion.
- In many cases, communicating with KubeVirt VMs makes use of the same protocols and schemes as non-Kubernetes-based environments.
- The management of VMs still represents a challenge.

For these reasons and more, it is only natural that a tool, like Ansible, is introduced within the KubeVirt community. Not only can it help manage KubeVirt and Kubernetes resources, like `VirtualMachines`, but also to enable the extensive Ansible ecosystem for managing guest configurations.

## Included capabilities

As part of the initial release, an [Ansible Inventory plugin](https://docs.ansible.com/ansible/latest/plugins/inventory.html) and management module is included. They are available in the same distribution location containing Ansible automation content, [Ansible Galaxy](https://galaxy.ansible.com/kubevirt/core). The resources encompassing the collection itself are detailed in the following sections.

### Inventory

To work with KubeVirt VMs in Ansible, they need to be available in Ansible's hosts [inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html). Since KubeVirt is already using the Kubernetes API to manage VMs, it would be nice to leverage this API to discover hosts with Ansible too. This is where the [dynamic inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_dynamic_inventory.html) of the `kubevirt.core` collection comes into play.

The dynamic inventory capability allows you to query the Kubernetes API for available VMs in a given namespace or namespaces, along with additional filtering options, such as labels. To allow Ansible to find the right connection parameters for a VM, the network name of a secondary interface can also be specified.

Under the hood, the dynamic inventory uses either your default kubectl credentials or credentials specified in the inventory parameters to establish the connection with a cluster.

### Managing VMs

While working with existing VMs is already quite useful, it would be even better to control the entire lifecycle of KubeVirt `VirtualMachines` from Ansible. This is made possible by the `kubevirt_vm` module provided by the `kubevirt.core` collection.

The `kubevirt_vm` module is a thin wrapper around the [kubernetes.core.k8s](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html) module and it allows you to control the essential fields of a KubeVirt `VirtualMachine`'s specification. In true Ansible fashion, this module tries to be as idempotent as possible and only makes changes to objects within Kubernetes if necessary. With its `wait` feature, it is possible to delay further tasks until a VM was successfully created or updated and the VM is in the ready state or was successfully deleted.

## Getting started

Now that we've provided an introduction to the featureset, it is time to illustrate how you can get up to speed using the collection including a few examples to showcase the capabilities provided by the collection.

### Prerequisites

Please note that as a prerequisite, Ansible needs to be installed and configured along with a working Kubernetes cluster with KubeVirt and the [KubeVirt Cluster Network Addons Operator](https://github.com/kubevirt/cluster-network-addons-operator). The cluster also needs to have a [secondary network configured](https://kubevirt.io/user-guide/virtual_machines/interfaces_and_networks/#bridge), which can be attached to VMs so that the machine can be reached from the Ansible control node.

### Items covered

1. Installing the collection from Ansible Galaxy
2. Creating a Namespace and a Secret with an SSH public key
3. Creating a VM
4. Listing available VMs
5. Executing a command on the VM
6. Removing the previously created resources

### Walkthrough

First, install the `kubevirt.core` collection from Ansible Galaxy:

```bash
ansible-galaxy collection install kubevirt.core
```

This will also install the `kubernetes.core` collection as a dependency.

Second, create a new Namespace and a Secret containing a public key for SSH authentication:

```bash
ssh-keygen -f my-key
kubectl create namespace kubevirt-ansible
kubectl create secret generic my-pub-key --from-file=key1=my-key.pub -n kubevirt-ansible
```

With the collection now installed and the public key pair created, create a file called `play-create.yml` containing an Ansible playbook to deploy a new VM called `testvm`:

```yaml
- hosts: localhost
  connection: local
  tasks:
  - name: Create VM
    kubevirt.core.kubevirt_vm:
      state: present
      name: testvm
      namespace: kubevirt-ansible
      labels:
        app: test
      instancetype:
        name: u1.medium
      preference:
        name: fedora
      spec:
        domain:
          devices:
            interfaces:
            - name: default
              masquerade: {}
            - name: secondary-network
              bridge: {}
        networks:
        - name: default
          pod: {}
        - name: secondary-network
          multus:
            networkName: secondary-network
        accessCredentials:
        - sshPublicKey:
            source:
              secret:
                secretName: my-pub-key
            propagationMethod:
              configDrive: {}
        volumes:
        - containerDisk:
            image: quay.io/containerdisks/fedora:latest
          name: containerdisk
        - cloudInitConfigDrive:
            userData: |-
              #cloud-config
              # The default username is: fedora
          name: cloudinit
      wait: yes
```

Run the playbook by executing the following command:

```bash
ansible-playbook play-create.yml
```

Once the playbook completes successfully, the defined VM will be running in the `kubevirt-ansible` namespace, which can be confirmed by querying for `VirtualMachines` in this namespace:

```bash
kubectl get VirtualMachine -n kubevirt-ansible
```

With the VM deployed, it is eligible for use in Ansible automation activities. Let's illustrate how it can be queried and added to an Ansible inventory dynamically using the plugin provided by the `kubevirt.core` collection.

Create a file called `inventory.kubevirt.yml` containing the following content:

```yaml
plugin: kubevirt.core.kubevirt
connections:
- namespaces:
  - kubevirt-ansible
  network_name: secondary-network
  label_selector: app=test
```

Use the `ansible-inventory` command to confirm the VM becomes added to the Ansible inventory:

```bash
ansible-inventory -i inventory.kubevirt.yml --list
```

Next, make use of the host by querying for all of the facts exposed by the VM using the setup module:

```bash
ansible -i inventory.kubevirt.yml -u fedora --key-file my-key all -m setup
```

Complete the lifecycle of the VM by destroying the previously created `VirtualMachine` and `Namespace`. Create a file called `play-delete.yml` containing the following playbook:

```yaml
- hosts: localhost
  tasks:
  - name: Delete VM
    kubevirt.core.kubevirt_vm:
      name: testvm
      namespace: kubevirt-ansible
      state: absent
      wait: yes
  - name: Delete namespace
    kubernetes.core.k8s:
      name: kubevirt-ansible
      api_version: v1
      kind: Namespace
      state: absent
```

Run the playbook to remove the VM:

```bash
ansible-playbook play-delete.yml
```

More information including the full list of parameters and options can be found within the collection documentation:

[https://kubevirt.io/kubevirt.core](https://kubevirt.io/kubevirt.core)

## What next?

This has been a brief introduction to the concepts and usage of the newly released `kubevirt.core` collection. Nevertheless, we hope that it helped to showcase the integration now available between KubeVirt and Ansible, including how easy it is to manage KubeVirt assets. A next potential iteration could be to expose a VM via a Kubernetes `Service` using one of the methods described in [this article](https://kubevirt.io/user-guide/virtual_machines/service_objects/#service-objects) instead of a secondary interface as was covered in this walkthrough. Not only does it leverage existing models outside the KubeVirt ecosystem, but it helps to enable a uniform method for exposing content.

Interested in learning more, providing feedback or contributing? Head over to the `kubevirt.core` GitHub repository to continue your journey and get involved.

[https://github.com/kubevirt/kubevirt.core](https://github.com/kubevirt/kubevirt.core)
