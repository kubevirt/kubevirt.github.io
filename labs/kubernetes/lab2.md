---
layout: labs
title: Experiment with CDI
permalink: /labs/kubernetes/lab2
lab: kubernetes
order: 1
---

# Experiment with the Containerized Data Importer (CDI)

[CDI](https://github.com/kubevirt/containerized-data-importer) is an utility designed to import Virtual Machine images for use with Kubevirt.

At a high level, a PersistentVolumeClaim (PVC) is created. A custom controller watches for importer specific claims, and when discovered, starts an import process to create a raw image named *disk.img* with the desired content into the associated PVC.

#### Install the CDI

We will first explore each component and install them. In this exercise we create a hostpath provisioner and storage class.

```bash
{% include scriptlets/lab2/01_get_storage_manifest.sh -%}
cat storage-setup.yml
{% include scriptlets/lab2/02_get_cdi_controller_manifest.sh -%}
cat cdi-controller.yaml
{% include scriptlets/lab2/03_create_storage.sh -%}
{% include scriptlets/lab2/04_create_cdi-controller.sh -%}
```

Review the "cdi" pods that were added.

```
{% include scriptlets/lab2/05_view_cdi_pod_status.sh -%}
```

#### Use the CDI

As an example, we will import a Fedora28 Cloud Image as a PVC and launch a Virtual Machine making use of it.

```bash
{% include scriptlets/lab2/06_create_fedora_cloud_instance.sh -%}
```

This will create the PVC with a proper annotation so that CDI controller detects it and launches an importer pod to gather the image specified in the *cdi.kubevirt.io/storage.import.endpoint* annotation.

```
{% include scriptlets/lab2/07_view_pod_logs.sh -%}
```

Notice that the importer downloaded the publicly available Fedora Cloud qcow image. Once the importer pod completes, this PVC is ready for use in kubevirt.

If the importer pod completes in error, you may need to retry it or specify a different URL to the fedora cloud image. To retry, first delete the importer pod and the {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_name }} PVC, and then recreate the {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_name }} PVC.

Let's create a Virtual Machine making use of it. Review the file *vm1_pvc.yml*.

```bash
{% include scriptlets/lab2/08_get_vm_manifest.sh -%}
cat ~/vm1_pvc.yml
```

We change the yaml definition of this Virtual Machine to inject the default public key of user in the cloud instance.

```
{% include scriptlets/lab2/09_create_vm1.sh -%}
```

This will create and start a Virtual Machine named vm1. We can use the following command to check our Virtual Machine is running and to gather its IP. You are looking for the IP address beside the `virt-launcher` pod.

```
{% include scriptlets/lab2/10_view_pods.sh -%}
```

Since we are running an all in one setup, the corresponding Virtual Machine is actually running on the same node, we can check its qemu process.

```
{% include scriptlets/lab2/11_view_vm_in_qemu.sh -%}
```

Wait for the Virtual Machine to boot and to be available for login. You may monitor its progress through the console. The speed at which the VM boots depends on whether baremetal hardware is used. It is much slower when nested virtualization is used, which is likely the case if you are completing this lab on an instance on a cloud provider.

```
{% include scriptlets/lab2/12_connect_to_vm1_console.sh -%}
```

Disconnect from the virtual machine console by typing: `ctrl+]`

Finally, use the gathered ip to connect to the Virtual Machine, create some files, stop and restart the Virtual Machine with virtctl and check how data persists.

```
{% include scriptlets/lab2/13_ssh_to_vm1.sh -%}
```

This concludes this section of the lab.

[Previous Lab]({{ site.baseurl }}/labs/kubernetes/lab1)
