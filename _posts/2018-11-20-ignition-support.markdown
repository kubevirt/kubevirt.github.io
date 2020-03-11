---
layout: post
author: karmab
description: Ignition Support
navbar_active: Blogs
pub-date: November 20
pub-year: 2018
category: news
comments: true
tags: [ignition, coreos, rhcos]
---

## Introduction

Ignition is a new provisioning utility designed specifically for CoreOS/RhCOS. At the most basic level, it is a tool for manipulating a node during early boot. This includes:

- Partitioning disks.
- Formatting partitions.
- Writing files (regular files, systemd units, networkd units).
- Configuring users and their associated ssh public keys.

Recently, we added support for it in KubeVirt so ignition data can now be embedded in a vm specification, through a dedicated annotation.
Ignition support is still needed in the guest operating system.

## Enabling Ignition Support

Ignition Support has to be enabled through a _feature gate_. This is achieved by creating (or editing ) the _kubevirt-config_ ConfigMap in the kubevirt namespace.

A minimal config map would look like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
  labels:
    kubevirt.io: ""
data:
  feature-gates: ExperimentalIgnitionSupport
```

Make sure to delete kubevirt related pods afterward for the configuration to be taken into account:

```sh
kubectl delete pod --all -n kubevirt
```

## WorkThrough

We assume that you already have a Kubernetes or OpenShift cluster running with KubeVirt installed.

### Step 1

Create The following VM spec in the file _myvm1.yml_:

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: myvm1
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/size: small
      annotations:
        kubevirt.io/ignitiondata: |
          {
              "ignition": {
                  "config": {},
                  "version": "2.2.0"
              },
              "networkd": {},
              "passwd": {
                  "users": [
                      {
                          "name": "core",
                          "sshAuthorizedKeys": [
                              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/AvM9VbO2yiIb9AillBp/kTr8jqIErRU1LFKqhwPTm4AtVIjFSaOuM4AlspfCUIz9IHBrDcZmbcYKai3lC3JtQic7M/a1OWUjWE1ML8CEvNsGPGu5yNVUQoWC0lmW5rzX9c6HvH8AcmfMmdyQ7SgcAnk0zir9jw8ed2TRAzHn3vXFd7+saZLihFJhXG4zB8vh7gJHjLfjIa3JHptWzW9AtqF9QsoBY/iu58Rf/hRnrfWscyN3x9pGCSEqdLSDv7HFuH2EabnvNFFQZr4J1FYzH/fKVY3Ppt3rf64UWCztDu7L44fPwwkI7nAzdmQVTaMoD3Ej8i7/OSFZsC2V5IBT kboumedh@bumblefoot"
                          ]
                      },
                  ]
              }
          }
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              bridge: {}
        resources:
          requests:
            memory: 64M
      networks:
        - name: default
          pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/fedora-cloud-container-disk-demo
```

> note "Note"
> We simply inject the ignition data as a string in _vm/spec/domain/spec/metadata/annotations_, using _kubevirt.io/ignitiondata_ as an annotation

### Step 2

Create the VM:

```sh
$ kubectl apply -f myvm1.yml
virtualmachine "myvm1" created
```

At this point, when VM boots, ignition data will be injected.

## How does it work under the hood?

We currently leverage [Pass-through of arbitrary qemu commands](https://libvirt.org/drvqemu.html#qemucommand) although there is some discussion around using a metadata server instead

## Summary

Ignition Support brings the ability to run CoreOS/RHCOS distros on KubeVirt and to customize them at boot time.
