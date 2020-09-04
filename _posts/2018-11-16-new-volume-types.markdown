---
layout: post
author: slintes
description: New Volume Types - ConfigMap, Secret and ServiceAccount
navbar_active: Blogs
pub-date: November 16
pub-year: 2018
category: news
comments: true
tags: [volume types, serviceaccount]
---

## Introduction

Recently three new volume types were introduced, which can be used for additional VM disks, and allow better integration of virtual machines with
well known Kubernetes resources.

## ConfigMap and Secret

Both [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
and [Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/) are used to provide configuration settings and credentials to Pods. In order to use them in your VM too, you can add them as additional disks, using the new `configMap`
and `secret` volume types.

## ServiceAccount

Kubernetes pods can be configured to get a special type of secret injected, which can be used for
[accessing the Kubernetes API](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod).
With the third new volume type `serviceAccount` you can get this information into your VM, too.

## Example

We assume that you already have a Kubernetes or OpenShift cluster running with KubeVirt installed.

### Step 1

Create a ConfigMap and Secret, which will be used in your VM:

```
$ kubectl create secret generic mysecret --from-literal=PASSWORD=hidden
secret "mysecret" created
$ kubectl create configmap myconfigmap --from-literal=DATABASE=staging
configmap "myconfigmap" created
```

### Step 2

Define a VirtualMachineInstance which uses all three new volume types, and save it to `vmi-fedora.yaml`.
Note how we add 3 disks for the ConfigMap and Secret we just created, and for the `default` ServiceAccount.
In order to automount these disks, we also add a `cloudInitNoCloud` disk with mount instructions. Details on
how to do this might vary depending on the VM's operating system.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: vmi-fedora
spec:
  domain:
    devices:
      disks:
        - name: containerdisk
          volumeName: containervolume
        - name: cloudinitdisk
          volumeName: cloudinitvolume
        - name: configmap-disk
          serial: configmap
          volumeName: configmap-volume
        - name: secret-disk
          serial: secret
          volumeName: secret-volume
        - name: serviceaccount-disk
          serial: serviceaccount
          volumeName: serviceaccount-volume
    resources:
      requests:
        memory: 1024M
  volumes:
    - name: containervolume
      containerDisk:
        image: kubevirt/fedora-cloud-container-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userData: |-
          #cloud-config
          password: fedora
          chpasswd: { expire: False }
          bootcmd:
            # mount the disks
            - "mkdir /mnt/{myconfigmap,mysecret,myserviceaccount}"
            - "mount /dev/disk/by-id/ata-QEMU_HARDDISK_configmap /mnt/myconfigmap"
            - "mount /dev/disk/by-id/ata-QEMU_HARDDISK_secret /mnt/mysecret"
            - "mount /dev/disk/by-id/ata-QEMU_HARDDISK_serviceaccount /mnt/myserviceaccount"
    - name: configmap-volume
      configMap:
        name: myconfigmap
    - name: secret-volume
      secret:
        secretName: mysecret
    - name: serviceaccount-volume
      serviceAccount:
        serviceAccountName: default
```

### Step 3

Create the VMI:

```sh
$ kubectl apply -f vmi-fedora.yaml
virtualmachineinstance "vmi-fedora" created
```

### Step 4

Inspect the new disks:

```sh
$ virtctl console vmi-fedora

vmi-fedora login: fedora
Password:

[fedora@vmi-fedora ~]$ ls -R /mnt/
/mnt/:
myconfigmap  mysecret  myserviceaccount

/mnt/myconfigmap:
DATABASE

/mnt/mysecret:
PASSWORD

/mnt/myserviceaccount:
ca.crt	namespace  token

[fedora@vmi-fedora ~]$ cat /mnt/myconfigmap/DATABASE
staging

[fedora@vmi-fedora ~]$ cat /mnt/mysecret/PASSWORD
hidden

[fedora@vmi-fedora ~]$ cat /mnt/myserviceaccount/namespace
default
```

## Summary

With these new volume types KubeVirt further improves the integration with native Kubernetes resources.
Learn more about all available volume types on the [userguide](https://kubevirt.io/user-guide/#/creation/disks-and-volumes).
