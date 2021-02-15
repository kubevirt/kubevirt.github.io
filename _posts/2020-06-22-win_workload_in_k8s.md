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
pub-date: June 22
pub-year: 2020
---

<p>The goal of this blog is to demonstrate that a web service can continue to run
after a Windows guest virtual machine providing the service is migrated from
MS Windows and Oracle VirtualBox to a guest virtual machine orchestrated by
Kubernetes and KubeVirt on a Fedora Linux host.  Yes!  It can be done!</p>

### Source details

* Host platform: Windows 2019 Datacenter
* Virtualization platform: Oracle VirtualBox 6.1
* Guest platform: Windows 2019 Datacenter (guest to be migrated)
<sup id="fnref:1" role="doc-noteref">
  <a href="#fn:1" class="footnote">1</a>
</sup>
* Guest application: My favorite dotnet application
[Jellyfin](https://jellyfin.org/)

### Target details

* Host platform: Fedora 32 with latest updates applied
* Kubernetes cluster created
* [KubeVirt](https://kubevirt.io/quickstart_minikube/) and [CDI](https://kubevirt.io/user-guide/operations/containerized_data_importer/) installed in the Kubernetes cluster.

## Procedure

### Tasks to performed on source host

<ol>
  <li>Before we begin let's take a moment to ensure the service is running and
  web browser accessible<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-1.png"
        width="100"
        height="60"
        itemprop="thumbnail"
        alt="Ensure application service is running">
    </div>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-2.png"
        width="100"
        height="60"
        itemprop="thumbnail"
        alt="Confirm web browser access">
    </div>
    <br><br>
  </li><li>Power down the guest virtual machine to ensure all changes to the
  filesystem are quiesced to disk.<br>
    <code>VBoxManage.exe controlvm testvm poweroff</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-3.png"
        width="115"
        height="20"
        itemprop="thumbnail"
        alt="Power down the guest virtual machine">
    </div>
    <br><br>
  </li><li>Upload the guest virtual machine disk image to the Kubernetes cluster
  and a target DataVolume called testvm
    <sup id="fnref:2" role="doc-noteref">
      <a href="#fn:2" class="footnote">2</a>
    </sup>
    <br>
    <code>
      virtctl.exe image-upload dv testvm
      --size=14Gi
      --image-path="C:\Users\Administrator\VirtualBox VMs\testvm\testvm.vdi"
    </code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-4.png"
        width="100"
        height="60"
        itemprop="thumbnail"
        alt="Upload disk image">
    </div>
    <br><br>
  </li><li>Verify the PersistentVolumeClaim created via the DataVolume
  image upload in the previous step<br>
    <code>
      kubectl describe pvc/testvm
    </code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-1.png"
        width="125"
        height="75"
        itemprop="thumbnail"
        alt="Verify PersistentVolumeClaim">
    </div>
  <br><br>
  </li><li>Create a guest virtual machine definition that references the
  DataVolume containing our guest virtual machine disk image<br>
    <code>kubectl create -f vm_testvm.yaml</code>
    <sup id="fnref:3" role="doc-noteref">
      <a href="#fn:3" class="footnote">3</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-2.png"
        width="125"
        height="75"
        itemprop="thumbnail"
        alt="Create the guest virtual machine">
    </div>
    <br><br>
  </li><li>Expose the Jellyfin service in Kubernetes via a NodePort type
  service<br>
    <code>
      kubectl create -f service_jellyfin.yaml
    </code>
    <sup id="fnref:4" role="doc-noteref">
      <a href="#fn:4" class="footnote">4</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-3.png"
        width="100"
        height="75"
        itemprop="thumbnail"
        alt="Create NodePort service">
    </div>
  <br><br>
  </li><li>Let's verify the running guest virtual machine by using the virtctl
  command to open a vnc session to the MS Window console.  While we are here
  let's also open a web browser and confirm web browser access to the
  application.<br>
    <code>virtctl vnc testvm</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-4.png"
        width="125"
        height="70"
        itemprop="thumbnail"
        alt="Verify running guest virtual machine">
    </div>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-5.png"
        width="125"
        height="70"
        itemprop="thumbnail"
        alt="Web browser access to application">
    </div>
    <br><br>
  </li>
</ol>

### Task to performed on user workstation

<ol>
  And finally let's confirm web browser access via the Kubernetes service url.<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-6.png"
        width="125"
        height="70"
        alt="Web browser access to Kubernetes service">
    </div>
    <br><br>
</ol>

### SUCCESS!

<p>Here we have successfully demonstrated how simple it can be to migrate an
existing MS Windows platform and application to Kubernetes control. For
questions feel free to join the conversation via one of the project forums.</p>

<br>

##### Footnotes

<div class="footnotes" role="doc-noteref">
  <ol>
    <li id="fn:1" role="doc-noteref">
      Fedora virtio drivers need to be installed on Windows hosts or virtual
      machines that will be migrated into a Kubernetes environment. Drivers can
      be found
      <a href="https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/">
        here
      </a>.
      <a href="#fnref:1" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li><li id="fn:2" role="doc-noteref">
      Please note:
      <br>
      &#8226; Users without certificate authority trusted certificates added to
      the kubernetes api and cdi cdi-proxyuploader secret will require the
      <code>--insecure</code> arg.
      <br>
      &#8226; Users without the uploadProxyURLOverride patch to the cdi
      cdiconfig.cdi.kubevirt.io/config crd will require the
      <code>--uploadProxyURL</code> arg.
      <br>
      &#8226; Users need a correctly configured $HOME/.kube/config along with
      client authentication certificate.
      <a href="#fnref:2" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li><li id="fn:3" role="doc-noteref">
      <a href="{% link assets/2020-06-22-win_workload_in_k8s/vm_testvm.yaml %}">
        vm_testvm.yaml
      </a>: Virtual machine manifest
      <a href="#fnref:3" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li><li id="fn:4" role="doc-noteref">
      <a href="{% link assets/2020-06-22-win_workload_in_k8s/service_jellyfin.yaml %}">
        service_jellyfin.yaml
      </a>: Service manifest
      <a href="#fnref:4" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li>
  </ol>
</div>
