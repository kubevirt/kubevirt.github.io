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

The goal of this blog is to demonstrate the migration of a Windows guest VM
running on a Windows host to a guest VM orchestrated by Kubernetes and KubeVirt
on a Fedora Linux host. Yes!  It can be done!

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
* KubeVirt installed with CDI

## Procedure

### Tasks to performed on source host

<ol>
  <li>Ensure application service is running<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-1.png"
        width="100"
        height="60"
        itemprop="thumbnail"
        alt="Ensure application service is running">
    </div>
    <br><br>
  </li><li>Confirm web browser access<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-2.png"
        width="100"
        height="60"
        itemprop="thumbnail"
        alt="Confirm web browser access">
    </div>
    <br><br>
  </li><li>Power down the guest VM<br>
    <code>VBoxManage.exe controlvm testvm poweroff</code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/1-3.png"
        width="115"
        height="20"
        itemprop="thumbnail"
        alt="Power down the guest VM">
    </div>
    <br><br>
  </li><li>Upload disk img
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
        alt="Upload disk img">
    </div>
  </li>
</ol>

### Tasks to performed on target host

<ol>
  <li>Verify PersistentVolumeClaim<br>
    <code>
      kubectl get pvc
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
  </li><li>Verify PersistentVolume<br>
    <code>
      I=$(kubectl get pvc/testvm -o jsonpath='{.spec.volumeName}');<br>
      kubectl describe pv/${I};<br>
      minikube ssh;<br>
      ls -la /var/lib/minikube/default-testvm-pvc*
    </code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-2.png"
        width="125"
        height="75"
        itemprop="thumbnail"
        alt="Verify PersistentVolume">
    </div>
    <br><br>
  </li><li>Create a guest VM<br>
    <code>kubectl create -f vm_testvm.yaml</code>
    <sup id="fnref:3" role="doc-noteref">
      <a href="#fn:3" class="footnote">3</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-3.png"
        width="125"
        height="75"
        itemprop="thumbnail"
        alt="Create a guest VM">
    </div>
    <br><br>
  </li><li>Create NodePort service for Jellyfin<br>
    <code>
      kubectl create -f service_jellyfin.yaml
    </code>
    <sup id="fnref:4" role="doc-noteref">
      <a href="#fn:4" class="footnote">4</a>
    </sup>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-4.png"
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
      minikube ip;<br>
      kubectl get service jellyfin -o jsonpath='{.spec.ports..nodePort}'
    </code>
    <br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-5.png"
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
        src="/assets/2020-06-22-win_workload_in_k8s/2-6.png"
        width="125"
        height="70"
        itemprop="thumbnail"
        alt="Verify running guest VM">
    </div>
    <br><br>
  </li><li>Confirm web browser access to app on guest VM<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-7.png"
        width="125"
        height="70"
        itemprop="thumbnail"
        alt="Guest web browser access">
    </div>
    <br><br>
  </li><li>Confirm web browser access to app on host<br>
    <div class="zoom">
      <img
        src="/assets/2020-06-22-win_workload_in_k8s/2-8.png"
        width="125"
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
      Fedora virtio drivers need to be installed on Windows hosts or VMs that will be
      migrated into a Kubernetes environment. Drivers can be found
      <a href="https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/">
        here
      </a>
      <a href="#fnref:1" class="reversefootnote" role="doc-noteref">&#8617;</a>
    </li><li id="fn:2" role="doc-noteref">
      Please note:
      <br>
      &#8226; users without certificate authority trusted x509 certificates
      added to the kubernetes api and cdi cdi-proxyuploader secret will require the `--insecure` arg.
      <br>
      &#8226; users without the uploadProxyURLOverride patch to the cdi cdiconfig.cdi.kubevirt.io/config crd
      will require the `--uploadProxyURL` arg.
      <br>
      &#8226; users need a correctly configured $HOME/.kube/config along with client authentication certificate
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

Fedora virtio drivers need to be installed on Windows hosts or VMs that will be
migrated into a Kubernetes environment. Drivers can be found
[here](https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/).
