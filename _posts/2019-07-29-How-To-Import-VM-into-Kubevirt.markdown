---
layout: post
author: DirectedSoul
title: How to import VM into KubeVirt
description: Import a VM into the Kubernetes Platform using CDI
navbar_active: Blogs
pub-date: Jul 29
pub-year: 2019
category: news
tags: [cdi, vm import]
---

## Introduction

Kubernetes has become the new way to orchestrate the containers and to handle the microservices, but what if I already have applications running on my old VM's in my datacenter ? Can those apps ever be made k8s friendly ? Well, if that is the use-case for you, then we have a solution with KubeVirt!

In this blog post we will show you how to deploy a VM as a yaml template and the required steps on how to import it as a [PVC](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) onto your kubernetes environment using the CDI and KubeVirt add-ons.

**Assumptions:**

- A basic understanding of the k8s architecture: In its simplest terms Kubernetes is a portable, extensible open-source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation. It has a large, rapidly growing ecosystem. Kubernetes services, support, and tools are widely available. For complete details check [Kubernetes-architecture](https://www.aquasec.com/wiki/display/containers/Kubernetes+Architecture+101)

- User is familiar with the concept of a [Libvirt based VM](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-guest_virtual_machine_installation_overview-creating_guests_with_virt_install)

- PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned by an administrator. Feel free to check more on [Persistent Volume(PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

- Persistent Volume Claim (PVC) is a request for storage by a user. It is similar to a pod. Pods consume node resources and PVCs consume PV resources. Feel free to check more on [Persistent Volume Claim(PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

- User is familiar with the concept of [KubeVirt-architecture](https://github.com/kubevirt/kubevirt/blob/master/docs/architecture.md) and [CDI-architecture](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/design.md#design)

- User has already installed KubeVirt in an available K8s environment, if not please follow the link [Installing KubeVirt](https://kubevirt.io/user-guide/#/installation/installation?id=installation) to further proceed.

- User is already familiar with VM operation with Kubernetes, for a refresher on how to use 'Virtual Machines' in Kubernetes, please do check [LAB 1]({% link labs/kubernetes/lab1.md %}) before proceeding.

## Creating Virtual Machines from local images with CDI and virtctl

The [Containerized Data Importer (CDI)](https://github.com/kubevirt/containerized-data-importer) project provides facilities for enabling Persistent Volume Claims (PVCs) to be used as disks for KubeVirt VMs. The three main CDI use cases are:

- Import a disk image from a URL to a PVC (HTTP/S3)
- Clone an existing PVC
- Upload a local disk image to a PVC

This document covers the third use case and covers the HTTP based import use case at the end of this post.

**NOTE**: You should have CDI installed in your cluster, a VM disk that you’d like to upload, and virtctl in your path

Please follow the instructions for the [installation of CDI](https://github.com/kubevirt/containerized-data-importer) (v1.9.0 as of this writing)

**Expose cdi-uploadproxy service:**

The cdi-uploadproxy service must be accessible from outside the cluster. Here are some ways to do that:

- [NodePort Service](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Route](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html)

We can take a look at example manifests [here](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/upload.md)

The supported image formats are:

- `.img`
- `.iso`
- `.qcow2`
- Compressed (`.tar`, `.gz` or `.xz`) of the above formats.

We will use [this image](http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img) from [CirrOS Project](https://launchpad.net/cirros) (in `.img` format)

We can use `virtctl` command for uploading the image as shown below:

```shell
virtctl image-upload --help
Upload a VM image to a PersistentVolumeClaim.

Usage:
  virtctl image-upload [flags]

Examples:
  # Upload a local disk image to a newly created PersistentVolumeClaim:
    virtctl image-upload --uploadproxy-url=https://cdi-uploadproxy.mycluster.com --pvc-name=upload-pvc --pvc-size=10Gi --image-path=/images/fedora28.qcow2

Flags:
      --access-mode string       The access mode for the PVC. (default "ReadWriteOnce")
  -h, --help                     help for image-upload
      --image-path string        Path to the local VM image.
      --insecure                 Allow insecure server connections when using HTTPS.
      --no-create                Don't attempt to create a new PVC.
      --pvc-name string          The destination PVC.
      --pvc-size string          The size of the PVC to create (ex. 10Gi, 500Mi).
      --storage-class string     The storage class for the PVC.
      --uploadproxy-url string   The URL of the cdi-upload proxy service.
      --wait-secs uint           Seconds to wait for upload pod to start. (default 60)

Use "virtctl options" for a list of global command-line options (applies to all commands).
```

### Creation of VirtualMachineInstance from a PVC

Here, `virtctl image-upload` works by creating a PVC of the requested size, sending an `UploadTokenRequest` to the `cdi-apiserver`, and uploading the file to the `cdi-uploadproxy`.

```shell
virtctl image-upload --pvc-name=cirros-vm-disk --pvc-size=500Mi --image-path=/home/shegde/images/cirros-0.4.0-x86_64-disk.img --uploadproxy-url=<url to upload proxy service>
```

The data inside are ephemeral meaning is lost when the VM restarts, in order to prevent that, and provide a persistent data storage, we use PVC (`persistentVolumeClaim`) which allows connecting a PersistentVolumeClaim to a VM disk.

```shell
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: cirros-vm
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: pvcdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: pvcdisk
    persistentVolumeClaim:
      claimName: cirros-vm-disk
status: {}
EOF
```

A `PersistentVolume` can be in `filesystem` or `block` mode:

- `Filesystem`: For KubeVirt to be able to consume the disk present on a PersistentVolume’s filesystem, the disk must be named `disk.img` and be placed in the root path of the filesystem. Currently the disk is also required to be in `raw` format.

  **Important**: The `disk.img` image file needs to be owned by the user-id `107` in order to avoid permission issues. Additionally, if the `disk.img` image file has not been created manually before starting a VM then it will be created automatically with the PersistentVolumeClaim size. Since not every storage provisioner provides volumes with the exact usable amount of space as requested (e.g. due to filesystem overhead), KubeVirt tolerates up to 10% less available space. This can be configured with the `pvc-tolerate-less-space-up-to-percent` value in the `kubevirt-config` ConfigMap.

- `Block`: Use a block volume for consuming raw block devices. To do that, `BlockVolume` feature gate must be enabled.

A simple example which attaches a PersistentVolumeClaim as a disk may look like this:

```yaml
metadata:
  name: testvmi-pvc
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
        - name: mypvcdisk
          lun: {}
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

### Creation with a DataVolume

DataVolumes are a way to automate importing virtual machine disks onto pvc's during the virtual machine’s launch flow. Without using a DataVolume, users have to prepare a pvc with a disk image before assigning it to a VM or VMI manifest. With a DataVolume, both the pvc creation and import is automated on behalf of the user.

#### DataVolume VM Behavior

DataVolumes can be defined in the VM spec directly by adding the DataVolumes to the dataVolumeTemplates list. Below is an example.

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-alpine-datavolume
  name: vm-alpine-datavolume
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-alpine-datavolume
    spec:
      domain:
        devices:
          disks:
            - disk:
                bus: virtio
              name: datavolumedisk1
        resources:
          requests:
            memory: 64M
      volumes:
        - dataVolume: #Note the type is dataVolume
            name: alpine-dv
          name: datavolumedisk1
  dataVolumeTemplates: # Automatically a PVC of size 2Gi is created
    - metadata:
        name: alpine-dv
      spec:
        pvc:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 2Gi
        source: #This is the source where the ISO file resides
          http:
            url: http://cdi-http-import-server.kubevirt/images/alpine.iso
```

From the above manifest the two main sections that needs an attention are **`source`** and **`pvc`**.

The `source` part declares that there is a disk image living on an http server that we want to use as a volume for this VM. The `pvc` part declares the spec that should be used to create the pvc that hosts the source data.

When this VM manifest is posted to the cluster, as part of the launch flow a pvc will be created using the spec provided and the source data will be automatically imported into that pvc before the VM starts. When the VM is deleted, the storage provisioned by the DataVolume will automatically be deleted as well.

#### A few caveats to be considered before using DataVolumes

From the above manifest the two main sections that needs an attention are `source` and `pvc`.

The `source` part declares that there is a disk image living on an http server that we want to use as a volume for this VM. The `pvc` part declares the spec that should be used to create the pvc that hosts the source data.

When this VM manifest is posted to the cluster as part of the launch flow, a pvc will be created using the spec provided and the source data will be automatically imported into that pvc before the VM starts. When the VM is deleted, the storage provisioned by the DataVolume will automatically be deleted as well.

A DataVolume is a custom resource provided by the Containerized Data Importer (CDI) project. KubeVirt integrates with CDI in order to provide users a workflow for dynamically creating pvcs and importing data into those pvcs.

In order to take advantage of the `DataVolume` volume source on a VM or VMI, the DataVolumes feature gate must be enabled in the `kubevirt-config` config map before KubeVirt is installed. CDI must also be installed(follow the steps as mentioned above).

#### Enabling the DataVolumes feature gate

Below is an example of how to enable DataVolume support using the kubevirt-config config map.

```shell
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
  labels:
    kubevirt.io: ""
data:
  feature-gates: "DataVolumes"
EOF
```

This config map assumes KubeVirt will be installed in the KubeVirt namespace. Change the namespace to suit your installation.

First post the configmap above, then install KubeVirt. At that point DataVolume integration will be enabled.

## Wrap-up

As demonstrated, VM can be imported as a k8s object using a CDI project along with KubeVirt. For more detailed insights, please feel free to follow the [KubeVirt project](https://kubevirt.io/).
