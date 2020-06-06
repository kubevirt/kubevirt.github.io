---
layout: post
author: Chris Callegari
description: This blog post outlines methods to migrate a sample Windows workload to Kubernetes using KubeVirt and CDI
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
    "images",
    "storage",
    "windows",
  ]
comments: true
title: Migrate a sample Windows workload to Kubernetes using KubeVirt and CDI
pub-date: June 06
pub-year: 2020
---

The goal of this blog is to demonstrate the migration of a Windows guest VM
running on a Windows host to a guest VM orchestrated by Kubernetes and KubeVirt
on a Fedora Linux host. Yes!  It can be done!

### Source details

* Metal: HP EliteDesk 800 G2 mini (Intel Core i5, 16 gig ram, 256 GiB ssd)
* Host platform: Windows 2019 Datacenter
* Virtualization platform: VirtualBox 6.1
* Guest platform: Windows 2019 Datacenter (guest to be migrated)
* Guest application: My favorite dotnet application
[Jellyfin](https://jellyfin.org/) for this demonstration

Install Firefox, Oracle VirtualBox 6.1, and then NGINX on the host.

A web server can be used to serve the VirtualBox virtual disk directory. This
allows the CDI importer to pull the data in over http. Install
[NGINX](https://nginx.org/) using the wizard and standard options. Edit the
configuration so that `C:\Users\<user>\VirtualBox VMs` directory is served.

[qemu-img](https://cloudbase.it/qemu-img-windows/) will be the tool used to
assist with converting the virtual disk image from VirtualBox vdi format to
qcow2. This step may or may not be necessary. qemu does have the ability to
natively run virtual machines with a variety of virtual disks types including
VirtualBox vdi and VMware vmdk.

Create a VirtualBox guest VM with specs of 1 vcpu, 2048 GiB of mem, and a 13
GiB thin provisioned virtual disk. Proceed with installing MS Windows 2019.
Fedora virtio drivers be installed on this VM. Drivers can be found
[here](https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/).
I've chosen my favorite Open Source dotnet application
[Jellyfin](https://jellyfin.org/) for this demonstration. Proceed with
installation. Select install as service. Application will run on port 8096.

### Target details

* Metal: HP EliteDesk 800 G2 mini (Intel Core i5, 16 gig ram, 256 GiB ssd)
* Host platform: Fedora 32 with latest updates applied

Be sure to make the following modifications the public zone of the firewalld ...
add service http, ports 30000-65535/tcp, source pod-network (check /etc/cni/net.d/).

#### Install Kubernetes Minikube

Documentation to deploy Kubernetes Minikube linked below.
* [KubeVirt Lab: Installing Minikube](https://kubevirt.io/quickstart_minikube/)
* [Kubernetes: Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

#### Install KubeVirt with CDI image importer

Documentation to deploy KubeVirt with CDI image importer linked below.
* [Installing KubeVirt](https://kubevirt.io/user-guide/#/installation/installation)
* [Installing CDI](https://kubevirt.io/user-guide/#/installation/image-upload?id=install-cdi)

## Procedure

### Tasks to performed on source host

<ol>
  <li>Ensure application service is running<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/1-1.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Ensure application service is running">
    </div>
    <br><br>
  </li><li>Confirm web browser access<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/1-2.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Confirm web browser access">
    </div>
    <br><br>
  </li><li>Power down the guest VM<br>
    <code>VBoxManage.exe controlvm testvm poweroff</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/1-3.png"
        width="100"
        height="20"
        itemprop="thumbnail"
        alt="Power down the guest VM">
    </div>
    <br><br>
  </li><li>Convert guest virtual disk img to qcow2<br>
    <code>qemu-img.exe convert -p -f vdi -O qcow2 \
    "C:\Users\Administrator\VirtualBox VMs\testvm\testvm.vdi" \
    "C:\Users\Administrator\VirtualBox VMs\testvm\testvm.qcow2"</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/1-4.png"
        width="100"
        height="20"
        itemprop="thumbnail"
        alt="Convert guest virtual disk img to qcow2">
    </div>
  </li>
</ol>

### Tasks to performed on target host

<ol>
  <li>Create the PersistentVolumeClaim<br>
    <code>
      kubectl create -f pvc_testvm.yaml
    </code><sup id="fnref:1" role="doc-noteref">
      <a href="#fn:1" class="footnote">1</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-1.png"
        width="100"
        height="15"
        itemprop="thumbnail"
        alt="Create the PersistentVolumeClaim">
    </div>
    <br><br>
  </li><li>Observe the importer log<br>
    <code>kubectl logs -f pod/importer-testvm</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-2.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Observe the importer log">
    </div>
    <br><br>
  </li><li>Verify PersistentVolumeClaim<br>
    <code>kubectl get pvc; kubectl describe pvc/testvm</code>
    <br>
    <div class="zoom">
      <img
          src="/assets/2020-06-08-win_workload_in_k8s/2-3.png"
          width="100"
          height="75"
          itemprop="thumbnail"
          alt="Verify PersistentVolumeClaim">
    </div>
    <br><br>
  </li><li>Verify PersistentVolume<br>
    <code>
      I=$(kubectl get pvc/testvm -o jsonpath='{.spec.volumeName}');
      kubectl describe pv/${I};
      minikube ssh;
      ls -la /var/lib/minikube/default-testvm-pvc*
    </code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-4.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Verify PersistentVolume">
    </div>
    <br><br>
  </li><li>Create a guest VM<br>
    <code>
      kubectl create -f vm_testvm.yaml
    </code><sup id="fnref:2" role="doc-noteref">
      <a href="#fn:2" class="footnote">2</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-5.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Create a guest VM">
    </div>
    <br><br>
  </li><li>Start minikube tunnel in a separate terminal<br>
    <code>minikube tunnel</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-6.png"
        width="100"
        height="50"
        itemprop="thumbnail"
        alt="Start minikube tunnel">
    </div>
    <br><br>
  </li><li>Create NodePort service<br>
    <code>
      kubectl create -f service_jellyfin.yaml
    </code><sup id="fnref:3" role="doc-noteref">
      <a href="#fn:3" class="footnote">3</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-7.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Create NodePort service">
    </div>
    <br><br>
  </li><li>Acquire service url from minikube<br>
    <code>
      minikube service jellyfin
    </code>
    <br><br>
    This data can also be acquired manually via the following:
    <br>
    <code>
      minikube ip;
      kubectl get service jellyfin -o jsonpath='{.spec.ports..nodePort}'
    </code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-8.png"
        width="100"
        height="50"
        itemprop="thumbnail"
        alt="Acquire service url">
    </div>
    > info "INFO"
    > Keep the minikube ip, and port in mind. These data points will
    > be used further along in the demo

    > warning "NOTICE"
    > A `<pending>` state in the `EXTERNAL-IP` column is indicative of an
    > issue. There must be an assigned IP in this column.

  <br><br>
  </li><li>Verify running guest VM<br>
    <code>virtctl vnc testvm</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-9.png"
        width="100"
        height="70"
        itemprop="thumbnail"
        alt="Verify running guest VM">
    </div>
    <br><br>
  </li><li>Confirm web browser access to app on guest VM<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-10.png"
        width="100"
        height="70"
        itemprop="thumbnail"
        alt="Guest web browser access">
    </div>
    <br><br>
  </li><li>Confirm web browser access to app on host<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-08-win_workload_in_k8s/2-11.png"
        width="100"
        height="70"
        alt="Host web browser access">
    </div>
    <br><br>
  </li>
</ol>

### SUCCESS!

<p>Here we have successfully demonstrated how simple it can be to migrate an
existing MS Windows platform and application to Kubernetes control. For
questions feel free to join the conversation via one of the project forums.</p>

<br>

### Example manifests
<div class="footnotes" role="doc-noteref">
  <ol>
    <li id="fn:1" role="doc-noteref">
      <a href="{% link assets/2020-06-08-win_workload_in_k8s/pvc_testvm.yaml %}">
        pvc_testvm.yaml
      </a>: PersistentVolumeClaim manifest
      <a href="#fnref:1" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li><li id="fn:2" role="doc-noteref">
        <a href="{% link assets/2020-06-08-win_workload_in_k8s/vm_testvm.yaml %}">
          vm_testvm.yaml
        </a>: Virtual machine manifest
        <a href="#fnref:2" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li><li id="fn:3" role="doc-noteref">
      <a href="{% link assets/2020-06-08-win_workload_in_k8s/service_jellyfin.yaml %}">
        service_jellyfin.yaml
      </a>: Service manifest
      <a href="#fnref:3" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li>
  </ol>
</div>
