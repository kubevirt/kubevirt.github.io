---
layout: post
author: Mark DeNeve
title: Using Intel vGPUs with Kubevirt
description: Excerpt of the Blog Post
navbar_active: Blogs
pub-date: April 30
pub-year: 2021
category: news
tags: [kubevirt, vGPU, Windows, GPU, Intel]
comments: true
---

<!-- TOC depthFrom:2 insertAnchor:false orderedList:false updateOnSave:true withLinks:true -->
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
  - [Centos Server Prep](#centos-server-prep)
  - [Preparing the Intel vGPU driver](#preparing-the-intel-vgpu-driver)
- [Install Kubernetes with minikube](#install-kubernetes-with-minikube)
- [Install kubevirt](#install-kubevirt)
  - [Validate vGPU detection](#validate-vgpu-detection)
  - [Install Containerize Data Importer](#install-containerize-data-importer)
- [Install Windows](#install-windows)
- [Accessing the Windows VM](#accessing-the-windows-vm)
- [Using the GPU](#using-the-gpu)
<!-- /TOC -->

## Introduction

Starting with 5th generation Intel Core processors that have embedded Intel graphics processing units it is possible to share the graphics processor between multiple virtual machines. In Linux, this sharing of a GPU is typically enabled through the use of mediated GPU devices, also known as vGPUs. Kubevirt has supported the use of GPUs including GPU passthrough and vGPU since v0.22.0 back in 2019. This support was centered around one specific vendor, and only worked with expensive enterprise class cards and required additional licensing. Starting with [Kubevirt 0.40](https://github.com/kubevirt/kubevirt/releases/tag/v0.40.0) support for detecting and allocating the Intel based vGPUs has been added to Kubevirt and, support for the virtualization of Intel GPUs is available in the Linux Kernel since 4.19. 

The total number of vGPUs you can create is dependent on your specific hardware as well as support for changing the Graphics aperture size and shared graphics memory within your BIOS. For more details on this see [Create vGPU \(KVMGT only\)](https://github.com/intel/gvt-linux/wiki/GVTg_Setup_Guide#53-create-vgpu-kvmgt-only) in the Intel GVTg wiki. Minimally configured devices can typically make at least two vGPU devices. 

You can reproduce this work on any Kubernetes cluster running kubevirt v0.40.0 or later, but the steps you need to take to load the kernel modules and enable the virtual devices will vary based on the underlying OS your Kubernetes cluster is running on. In order to demonstrate how you can enable this feature, we will use an all-in-one Kubernetes cluster built using Centos 8.3 and minikube. 

> note "Note"
> This blog post is a more advanced topic and assumes some Linux and Kubernetes understanding.

## Prerequisites

Before we begin you will need a few things to make use of the Intel GPU:

* A workstation or server with a 5th Generation or higher Intel Core Processor, or E3_v4 or higher Xeon Processor and enough memory to virtualize one or more VMs 
* A preinstalled Centos 8.3 OS Server, using the Minimal install
* The following software:
  * minikube - See [minikube start](https://kubevirt.io/quickstart_minikube/)
  * virtctl - See [kubevirt releases](https://github.com/kubevirt/kubevirt/releases)
  * kubectl - See [Install and Set Up kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* A Windows 10 Install ISO Image - See [Download Windows 10 Disk Image](https://www.microsoft.com/en-us/software-download/windows10)

### Centos Server Prep

In order to use minikube on Centos 8.3 we will be installing the Docker binaries as these allow you to do a "bare metal" install of Kubernetes onto your Centos box. Use the following commands to update your Centos host and install Docker:

```
$ sudo dnf update
$ sudo dnf install -y pciutils yum-utils conntrack
$ sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum install -y docker-ce docker-ce-cli containerd.io    
$ sudo systemctl enable docker --now
$ sudo usermod -a -G docker $USER
```
> note "Note"
> In order to simplify this demo box, and make it easier to access our virtual machine, we are going to disable selinux and firewalld. These changes are NOT required for using the Intel vGPU drivers, but are done to make the test server easier to use. Don't use this type of configuration in Production! You have been warned.

```
$ sudo systemctl disable firewalld
$ sudo vi /etc/selinux/config
# change the "SELINUX=enforcing" to "SELINUX=permissive"
$ sudo setenforce 0
$ sudo shutdown -r now
```

### Preparing the Intel vGPU driver

In order to make use of the Intel vGPU driver, we need to make a few changes to our all-in-one host. The commands below assume you are using a Centos based host. If you are using a different base OS, be sure to update your commands for that specific distribution. 

The following commands will do the following:
* enable gvt in the i915 module
* load the kvmgt module to enable support within kvm
* update the Linux kernel to enable Intel IOMMU

```shell
$ sudo echo kvmgt > /etc/modules-load.d/gpu-kvmgt.conf
$ sudo grubby --update-kernel=ALL --args="intel_iommu=on i915.enable_gvt=1"
$ sudo shutdown -r now
```

After the reboot check to ensure that the proper kernel modules have been loaded:

```shell
$ sudo lsmod | grep kvmgt
kvmgt                  32768  0
mdev                   20480  2 kvmgt,vfio_mdev
vfio                   32768  3 kvmgt,vfio_mdev,vfio_iommu_type1
kvm                   798720  2 kvmgt,kvm_intel
i915                 2494464  4 kvmgt
drm                   557056  4 drm_kms_helper,kvmgt,i915
```

We will now create our virtual GPU devices. These virtual devices are created by echoing a GUID into a sys device created by the Intel driver. This needs to be done every time the system boots. The easiest way to do this is using a systemd service that runs on every boot. Before we create this systemd service, we need to validate the PCI ID of your Intel Graphics card. To do this we will use the `lspci` command

```shell
$ sudo lspci
00:00.0 Host bridge: Intel Corporation Device 9b53 (rev 03)
00:02.0 VGA compatible controller: Intel Corporation Device 9bc8 (rev 03)
00:08.0 System peripheral: Intel Corporation Xeon E3-1200 v5/v6 / E3-1500 v5 / 6th/7th/8th Gen Core Processor Gaussian Mixture Model
```

Take note that in the above output the Intel GPU is on "00:02.0". Now create the `/etc/systemd/system/gvtg-enable.service` but be sure to update the PCI ID as appropriate for your machine:

```shell
$ sudo su - 
$ cat > /etc/systemd/system/gvtg-enable.service << EOM
[Unit]
Description=Create Intel GVT-g vGPU

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo '56a4c4e2-c81f-4cba-82bf-af46c30ea32d' > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_8/create"
ExecStart=/bin/sh -c "echo '973069b7-2025-406b-b3c9-301016af3150' > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_8/create"
ExecStop=/bin/sh -c "echo '1' > /sys/devices/pci0000:00/0000:00:02.0/56a4c4e2-c81f-4cba-82bf-af46c30ea32d/remove"
ExecStop=/bin/sh -c "echo '1' > /sys/devices/pci0000:00/0000:00:02.0/973069b7-2025-406b-b3c9-301016af3150/remove"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOM
$ exit
$ sudo systemctl enable gvtg-enable --now
```

We can validate that the vGPU devices were created by looking in the `/sys/devices/pci0000:00/0000:00:02.0/` directory. 

```shell
$ ls -lsa /sys/devices/pci0000:00/0000:00:02.0/56a4c4e2-c81f-4cba-82bf-af46c30ea32d
total 0
lrwxrwxrwx. 1 root root    0 Apr 20 13:56 driver -> ../../../../bus/mdev/drivers/vfio_mdev
drwxr-xr-x. 2 root root    0 Apr 20 14:41 intel_vgpu
lrwxrwxrwx. 1 root root    0 Apr 20 14:41 iommu_group -> ../../../../kernel/iommu_groups/8
lrwxrwxrwx. 1 root root    0 Apr 20 14:41 mdev_type -> ../mdev_supported_types/i915-GVTg_V5_8
drwxr-xr-x. 2 root root    0 Apr 20 14:41 power
--w-------. 1 root root 4096 Apr 20 14:41 remove
lrwxrwxrwx. 1 root root    0 Apr 20 13:56 subsystem -> ../../../../bus/mdev
-rw-r--r--. 1 root root 4096 Apr 20 13:56 uevent
```

Note that "mdev_type" points to "i915-GVTg_V5_8", this will come into play later when we configure kubevirt to detect the vGPU.

## Install Kubernetes with minikube

We will be using the minikube driver "none" which will install Kubernetes directly onto this server. This will allow you to maintain a copy of the virtual machines that you build through a reboot. Minikube will use the storage mounted on `/tmp/hostpath-provisioner`. Ensure that you have enough storage available in that path for storing both a Windows ISO install file as well as a virtual disk image. I suggest at least 80GB of free space for this demo.

```shell
$ minikube start --driver=none
😄  minikube v1.19.0 on Centos 8.3.2011
✨  Using the none driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🤹  Running on localhost (CPUs=12, Memory=31703MB, Disk=71645MB) ...
ℹ️  OS release is CentOS Linux 8
🐳  Preparing Kubernetes v1.20.2 on Docker 20.10.6 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🤹  Configuring local host environment ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

Once the minikube install is complete, validate that everything is working properly.

```shell
$ kubectl get nodes
NAME       STATUS   ROLES                  AGE    VERSION
kubevirt   Ready    control-plane,master   4m5s   v1.20.2
```

As long as you don't get any errors, your base Kubernetes cluster is ready to go.

## Install kubevirt

Our all-in-one Kubernetes cluster is now ready for installing Installing Kubevirt. The following steps are copied from the [KubeVirt quickstart with minikube](https://kubevirt.io/quickstart_minikube/)

```shell
$ minikube addons enable kubevirt
$ kubectl -n kubevirt wait kubevirt kubevirt --for condition=Available
```

At this point, we need to update our instance of kubevirt in the cluster. We need to configure kubevirt to detect the Intel vGPU by giving it an _mdevNameSelector_ to look for, and a _resourceName_ to assign to it. The _mdevNameSelector_ comes from the "mdev_type" that we identified earlier when we created the two virtual GPUs. When the kubevirt device manager finds instances of this mdev type, it will record this information and tag the node with the identified resourceName. We will use this resourceName later when we start up our virtual machine.

```
$ cat > kubevirt-patch.yaml <<EOF
spec:
  configuration:
    developerConfiguration:
      featureGates:
      - GPU
    permittedHostDevices:
      mediatedDevices:
      - mdevNameSelector: "i915-GVTg_V5_8"
        resourceName: "intel.com/U630"
EOF
$ kubectl patch kubevirt kubevirt -n kubevirt --patch "$(cat kubevirt-patch.yaml)" --type=merge
```

We now need to wait for kubevirt to reload its configuration. Run `kubectl -n kubevirt wait kv kubevirt --for condition=Available` and wait for this to complete successfully. NOTE you may need to run the command more than once depending on how long it takes for your machine to start kubevirt.

### Validate vGPU detection

Now that kubevirt is installed and running, lets ensure that the vGPU was identified correctly. Describe the minikube node, using the command `kubectl describe node` and look for the "Capacity" section. If kubevirt properly detected the vGPU you will see an entry for "intel.com/U630" with a capacity value of greater than 0. 

```shell
$ kubectl describe node
Name:               kubevirt
Roles:              control-plane,master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
...
Capacity:
  cpu:                            12
  devices.kubevirt.io/kvm:        110
  devices.kubevirt.io/tun:        110
  devices.kubevirt.io/vhost-net:  110
  ephemeral-storage:              71645Mi
  hugepages-1Gi:                  0
  hugepages-2Mi:                  0
  intel.com/U630:                 2
  memory:                         11822640Ki
  pods:                           110
```

There it is, intel.com/U630 - two of them are available.  Now all we need is a virtual machine to consume them.

### Install Containerize Data Importer

In order to install Windows 10, we are going to need to upload a Windows 10 install ISO to the cluster. This can be facilitated through the use of the Containerized Data Importer. The following steps are taken from the [Experiment with the Containerized Data Importer (CDI)](https://kubevirt.io/labs/kubernetes/lab2.html) web page:

```shell
$ export VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
$ kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
$ kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
```

Validate that Containerize Data Importer installed and is running:

```shell
$ kubectl get cdi cdi -n cdi
```

## Install Windows

At this point we can now install a Windows VM in order to test this feature. The steps below are based on [KubeVirt: installing Microsoft Windows from an ISO](https://kubevirt.io/2020/KubeVirt-installing_Microsoft_Windows_from_an_iso.html) however we will be using Windows 10 instead of Windows Server 2012. The commands below assume that you have a Windows 10 ISO file called `win10-virtio.iso`

Start by getting the ClusterIP that is in use for the CDI upload proxy:

```shell
$ kubectl get services -n cdi
NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
cdi-api           ClusterIP   10.96.117.29   <none>        443/TCP   6d18h
cdi-uploadproxy   ClusterIP   10.96.164.35   <none>        443/TCP   6d18h
```

In the above example, the IP we are after is "10.96.164.35". Using this IP address we will upload the win10-virtio.iso file to the cluster. Be sure to update the image-path as well as the pvc-size based on your Windows 10 ISO:

```shell
$ virtctl image-upload \
   --image-path=win10-virtio.iso \
   --pvc-name=iso-win10 \
   --access-mode=ReadWriteOnce \
   --pvc-size=5G \
   --uploadproxy-url=https://10.96.164.35:443 \
   --insecure \
   --wait-secs=240
```

We need a place to store our Windows 10 virtual disk, use the following to create a 40Gb space to store our file:

```shell
$ cat > win10-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: winhd1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 40Gi
EOF
$ kubectl create -f win10-pvc.yaml
```

We can now create our Windows 10 virtual machine. Use the following to create a virtual machine definition file that includes a vGPU:

```shell
$ cat > win10vm1.yaml << EOF
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: win10vm1
spec:
  running: false
  template:
    metadata:
      creationTimestamp: null
      labels:
        kubevirt.io/domain: win10vm1
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
          cores: 1
          sockets: 2
          threads: 1
        devices:
          gpus:
          - deviceName: intel.com/U630
            name: gpu1
          disks:
          - cdrom:
              bus: sata
            name: windows-guest-tools
          - bootOrder: 1
            cdrom:
              bus: sata
            name: cdrom
          - bootOrder: 2
            disk:
              bus: sata
            name: disk-1
          inputs:
          - bus: usb
            name: tablet
            type: tablet
          interfaces:
          - masquerade: {}
            model: e1000e
            name: nic-0
        features:
          acpi: {}
          apic: {}
          hyperv:
            relaxed: {}
            spinlocks:
              spinlocks: 8191
            vapic: {}
        machine:
          type: pc-q35-rhel8.2.0
        resources:
          requests:
            memory: 8Gi
      evictionStrategy: LiveMigrate
      hostname: win10vm1
      networks:
      - name: nic-0
        pod: {}
      terminationGracePeriodSeconds: 3600
      volumes:
        - name: cdrom
          persistentVolumeClaim:
            claimName: iso-win10
        - name: disk-1
          persistentVolumeClaim:
            claimName: winhd1
        - containerDisk:
            image: quay.io/kubevirt/virtio-container-disk
          name: windows-guest-tools
EOF
$ kubectl create -f win10vm1.yaml
```
> note "NOTE"
> This VM is not optimized to use virtio devices to simplify the OS install. By using SATA devices as well as an emulated e1000 network card, we do not need to worry about loading additional drivers. 

The key piece of information here is this snippet of yaml:

``` yaml
        devices:
          gpus:
          - deviceName: intel.com/U630
            name: gpu1
```

Here we are identifying the gpu device that we want to attach to this VM. The rest is handled by kubevirt.

We can now start the virtual machine with `virtctl start win10vm1`. Check to ensure that the VM is running with `kubectl get vm`.

## Accessing the Windows VM

Since the Windows VM is running on a machine that has no graphical interface, we are going to use some port forwarding tricks to access the kubevirt VNC console. the virtctl command has the ability to create a connection to the kubevirt console, on a specific port, so we will run `virtctl vnc win10vm1 --port 12345 --proxy-only`. Now from a separate machine SSH to the machine running kubevirt and use SSH port forwarding to connect your local port 12345 to the remote port 12345:

```shell
$ ssh -L 12345:localhost:12345 <username>@<kubevirt host name ror IP>
```

Once you are connected open up a VNC client and connect to "localhost:12345". There is no password associated with this session. Follow the standard process to install Windows 10 in this VM.

Once the install is complete you have a Windows 10 VM running with a GPU available. You can test that GPU acceleration is available by opening the Windows 10 task manager, selecting Advanced and then select the "Performance" tab. The GPU card should now be listed.

## Using the GPU

One last thing... GPU acceleration is not available over the VNC connection. In order to take advantage of the virtual GPU we have added, we will need to connect to the virtual machine over Remote Desktop Protocol (RDP). In the Windows 10 search bar, type "Remote Desktop Settings" and then open the result. Select "Enable Remote Desktop" and confirm the change. 

Now, run the following commands in order to expose the RDP server to outside your Kubernetes cluster:

```shell
$ virtctl expose vm win10vm1 --port=3389 --type=NodePort --name=win10vm1-rdp
$ kubectl get svc
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP          18h
win10vm1-rdp   NodePort    10.105.159.184   <none>        3389:30627/TCP   39s
```

Using your favorite RDP client, open a connection to the VM. Use the MAIN IP address of the Centos machine and the node port that is shown in the output above. For example, using the output from the `kubectl get svc` command above, connect to `<centos server ip>:30627`. When prompted use the username and password you created when installing Windows 10. You can now test the GPU acceleration. 

The easiest way to do this is open a web browser, and goto [http://www.fishgl.com](http://www.fishgl.com).
<br>

<div class="my-gallery" itemscope itemtype="http://schema.org/ImageGallery">
  <figure
    itemprop="associatedMedia"
    itemscope
    itemtype="http://schema.org/ImageObject"
  >
    <a
      href="/assets/2021-04-30-intel-vgpu-kubevirt/fishgl.png"
      itemprop="contentUrl"
      data-size="800x530"
    >
      <img
        src="/assets/2021-04-30-intel-vgpu-kubevirt/fishgl.png"
        itemprop="thumbnail"
        width="100%"
        alt="FishGL"
      />
    </a>
    <figcaption itemprop="caption description"></figcaption>
  </figure>
</div>

Congratulations! You now have a VM running in kubernetes using a virtual Intel GPU.