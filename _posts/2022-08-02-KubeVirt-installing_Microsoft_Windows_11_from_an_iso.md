---
layout: post
author: Jed Lejosne
description: "This blog post describes how to create a Microsoft Windows 11 virtual machine with KubeVirt"
navbar_active: Blogs
category: news
comments: true
tags:
  [
    kubevirt,
    kubernetes,
    "virtual machine",
    "Microsoft Windows kubernetes",
    "Microsoft Windows container",
    Windows,
  ]
title: "KubeVirt: installing Microsoft Windows 11 from an ISO"
pub-date: August, 2
pub-year: 2022
---

This blog post describes a simple way to deploy a Windows 11 VM with KubeVirt, using an installation ISO as a starting point.  
Although only tested with Windows 11, the steps described here should also work to deploy other recent versions of Windows.

## Pre-requisites

- You'll need a Kubernetes cluster with worker node(s) that have at least 6GB of available memory
- [KubeVirt](https://kubevirt.io/user-guide) and [CDI](https://github.com/kubevirt/containerized-data-importer/blob/main/README.md) both deployed on the cluster
- A storage backend, such as [Rook Ceph](https://ceph.com/)
- A Windows iso. One can be found at [https://www.microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11)

A suitable test cluster can easily be deployed thanks to KubeVirtCI by running the following commands from the [KubeVirt source repository](https://github.com/kubevirt/kubevirt):
```sh
$ export KUBEVIRT_MEMORY_SIZE=8192M
$ export KUBEVIRT_STORAGE=rook-ceph-default
$ make cluster-up && make cluster-sync
```

## Preparation

Before the virtual machine can be created, we need to setup storage volumes for the ISO and the drive, and write the appropriate VM(I) yaml.

1. Uploading the ISO to a PVC

   KubeVirt provides a simple tool that is able to do that for us: `virtctl`.  
   Here's the command to upload the ISO, just replace `/storage/win11.iso` with the path to your Windows 11 ISO:
   `virtctl image-upload pvc win11cd-pvc --size 6Gi --image-path=/storage/win11.iso --insecure`

2. Creating a persistent volume to use as the Windows drive

   This will depend on the storage configuration of your cluster.
   The following yaml, to apply to the cluster using `kubectl create`, should work just fine on a KubeVirtCI cluster:

   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: task-pv-volume
     labels:
       type: local
   spec:
     storageClassName: hostpath
     capacity:
       storage: 15Gi
     accessModes:
       - ReadWriteOnce
     hostPath:
       path: "/tmp/hostImages/win11"
   ```

   > note "Note"
   > Microsoft actually [recommends](https://docs.microsoft.com/en-us/windows/whats-new/windows-11-requirements) at least 64GB of storage.
   > But, unlike some other requirements, the installer will accept smaller disks.
   > This is convenient when testing with KubeVirtCI, as nodes only have about 20GB of free space.
   > However, please bear in mind that such a small drive should only be used for testing purposes, and might lead to instabilities.

3. Creating a persistent volume claim (PVC) for the drive

   Once again, your milage may vary, but the following PVC yaml works fine on KubeVirtCI:

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: disk-windows
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 15Gi
     storageClassName: hostpath
   ```

   The name of PVC, `disk-windows` here, will be used in the yaml of the VM(I) as the main volume.

4. Creating the VM(I) yaml file

   KubeVirt already includes an example [Windows VMI yaml file](https://github.com/kubevirt/kubevirt/blob/main/examples/vmi-windows.yaml), which we'll use as a starting point here for convenience.  
   Using a VMI yaml is more than enough for testing purposes, however for more serious applications you might want to consider changing it into a VM.
   
   First, in the yaml above, bump the memory up to 4Gi, which is a hard requirement of Windows 11. (Windows 10 is happy with 2Gi).
   
   Then, let's add the ISO created above.
   Add is as a cdrom in the disks section:
   ```yaml
   - cdrom:
       bus: sata
     name: winiso
   ```
   And the corresponding volume at the bottom:
   ```yaml
     - name: winiso
       persistentVolumeClaim:
         claimName: win11cd-pvc
   ```
   Note that the names should match, and that the `claimName` is what we used in the `virtctl` command above.
   
   Here is what the VMI looks like after those changes:
   ```yaml
   ---
   apiVersion: kubevirt.io/v1
   kind: VirtualMachineInstance
   metadata:
     labels:
       special: vmi-windows
     name: vmi-windows
   spec:
     domain:
       clock:
         timer:
           hpet:
             present: false
           hyperv: {}
           pit:
             tickPolicy: delay
           rtc:
             tickPolicy: catchup
         utc: {}
       cpu:
         cores: 2
       devices:
         disks:
         - disk:
             bus: sata
           name: pvcdisk
         - cdrom:
             bus: sata
           name: winiso
         interfaces:
         - masquerade: {}
           model: e1000
           name: default
         tpm: {}
       features:
         acpi: {}
         apic: {}
         hyperv:
           relaxed: {}
           spinlocks:
             spinlocks: 8191
           vapic: {}
         smm: {}
       firmware:
         bootloader:
           efi:
             secureBoot: true
         uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
       resources:
         requests:
           memory: 4Gi
     networks:
     - name: default
       pod: {}
     terminationGracePeriodSeconds: 0
     volumes:
     - name: pvcdisk
       persistentVolumeClaim:
         claimName: disk-windows
     - name: winiso
       persistentVolumeClaim:
         claimName: win11cd-pvc
   ```

   > note "Note"
   > When customizing this VMI definition or creating your own, please keep in mind that the TPM device and the UEFI firmware with SecureBoot are both hard requirements of Windows 11.
   > Not having them will cause the Windows 11 installation to fail early. Please also note that the SMM CPU feature is required for UEFI + SecureBoot.
   > However, they can all be omitted in the case of a Windows 10 VM(I).
   > Finally, we do not currently support TPM persistence, so any secret stored in the emulated TPM will be lost next time you boot the VMI.
   > For example, do not enable BitLocker, as it will fail to find the encryption key next boot and you will have to manually enter the (55 characters!) recovery key each boot.

## Windows installation

You should now be able to create the VMI and start the Windows installation process.  
Just use kubectl to start the VMI created above: `kubectl create -f vmi-windows.yaml`.  
Shortly after, open a VNC session to it using `virtctl vnc vmi-windows` (keep trying until the VMI is running and the VNC session pops up).  
You should now see the boot screen, and shortly after a prompt to "Press any key to boot from CD or DVD...". You have a few seconds to do so or the VM will fail to boot.
Then just follow the steps to install Windows.

## VirtIO drivers installation (optional)

Once Windows is installed, it's a good ideas to install the [VirtIO](http://www.linux-kvm.org/page/Virtio) drivers inside the VM, as they can drastically improve performance.
The latest version can be downloaded [here](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/).
`virtio-win-gt-x64.msi` is the simplest package to install, as you just have to run it as Administrator.

Alternatively, KubeVirt has a containerdisk image that can be mounted inside the VM.  
To use it, just add a simple cdrom disk to the VMI, like:
```yaml
- cdrom:
    bus: sata
  name: virtio
```
and the volume:
```yaml
  - containerDisk:
      image: kubevirt/virtio-container-disk
    name: virtio
```
When using KubeVirtCI, a local copy of the image is also available at `registry:5000/kubevirt/virtio-container-disk:devel`.

## Further performance improvements

Windows is quite resource-hungry, and you might find that the VM created above is too slow, even with the VirtIO drivers installed.  
Here are a few steps you can take to improve things:
- Increasing the RAM is always a good idea, if you have enough available of course.  
- Increasing the number of CPUs, and/or using CPUManager to assign dedicated CPU to the VM should also help a lot.
- Once the VirtIO drivers are installed, the main drive can also be switched from `sata` to `virtio`, and the attached CDROMs can be removed.
