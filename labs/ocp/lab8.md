---
layout: ocp
title: APBs and the Service Catalog
permalink: /labs/ocp/lab8
lab: ocp
order: 1
---

# APBs and the Service Catalog

You can provision KubeVirt using APBs through the Service Catalog.

Navigate to `https://student<number>.cnvlab.gce.sysdeseng.com:8443` in your browser.

<img src="/assets/images/labs/ocp/catalog-home.png" class="img-fluid" alt="Catalog Home">

Click the `Kubevirt` icon in the catalog to pull up the info page, then click `Next`.

<img src="/assets/images/labs/ocp/kubevirt-apb-info.png" class="img-fluid" alt="APB Info">

Configure KubeVirt.  Enter a user and password of an admin user (user: `developer` password: <any>) and fill out any fields.

<img src="/assets/images/labs/ocp/kubevirt-apb-config.png" class="img-fluid" alt="APB Config">

Enter the namespace where you launched kubevirt and watch it get provisioned.

<img src="/assets/images/labs/ocp/provisioned-kubevirt.png" class="img-fluid" alt="Provisioned KubeVirt">

Click the `Virtualization` tab to see any VM templates you want to create.

<img src="/assets/images/labs/ocp/virtualization-tab.png" class="img-fluid" alt="Virt Tab">

This concludes this section of the lab.

---

[Next Lab]({{ site.baseurl }}/labs/ocp/lab9)\
[Previous Lab]({{ site.baseurl }}/labs/ocp/lab7)
