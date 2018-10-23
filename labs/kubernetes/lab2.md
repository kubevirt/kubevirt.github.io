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
wget {{ site.data.labs_kubernetes_variables.cdi_lab.storage_setup_manifest }}
cat storage-setup.yml
wget {{ site.data.labs_kubernetes_variables.cdi_lab.cdi_controller_manifest }}
cat cdi-controller.yaml
kubectl create -f storage-setup.yml
kubectl create -f cdi-controller.yaml
```

Review the "cdi" pods that were added.

```
{{ site.data.labs_kubernetes_variables.cdi_lab.cdi_pod_listing_command }}
```

#### Use the CDI

As an example, we will import a Fedora28 Cloud Image as a PVC and launch a Virtual Machine making use of it.

```bash
kubectl create -f {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_manifest }}
```

This will create the PVC with a proper annotation so that CDI controller detects it and launches an importer pod to gather the image specified in the *cdi.kubevirt.io/storage.import.endpoint* annotation.

```
kubectl get pvc {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_name }} -o yaml
kubectl get pod
# replace with your importer pod name
kubectl logs importer-fedora-pnbqh   # Substitute your importer-fedora pod name here.
```

Notice that the importer downloaded the publicly available Fedora Cloud qcow image. Once the importer pod completes, this PVC is ready for use in kubevirt.

If the importer pod completes in error, you may need to retry it or specify a different URL to the fedora cloud image. To retry, first delete the importer pod and the {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_name }} PVC, and then recreate the {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_name }} PVC.

Let's create a Virtual Machine making use of it. Review the file *vm1_pvc.yml*.

```bash
wget {{ site.data.labs_kubernetes_variables.cdi_lab.vm_manifest }}
cat ~/vm1_pvc.yml
```

We change the yaml definition of this Virtual Machine to inject the default public key of user in the cloud instance.

```
# Generate a password-less SSH key using the default location.
ssh-keygen
PUBKEY=`cat ~/.ssh/id_rsa.pub`
sed -i "s%ssh-rsa.*%$PUBKEY%" vm1_pvc.yml
kubectl create -f vm1_pvc.yml
```

This will create and start a Virtual Machine named vm1. We can use the following command to check our Virtual Machine is running and to gather its IP. You are looking for the IP address beside the `virt-launcher` pod.

```
kubectl get pod -o wide
```

Since we are running an all in one setup, the corresponding Virtual Machine is actually running on the same node, we can check its qemu process.

```
ps -ef | grep qemu | grep {{ site.data.labs_kubernetes_variables.cdi_lab.vm_name }}
```

Wait for the Virtual Machine to boot and to be available for login. You may monitor its progress through the console. The speed at which the VM boots depends on whether baremetal hardware is used. It is much slower when nested virtualization is used, which is likely the case if you are completing this lab on an instance on a cloud provider.

```
./virtctl console {{ site.data.labs_kubernetes_variables.cdi_lab.vm_name }}
```

Disconnect from the virtual machine console by typing: `ctrl+]`

Finally, use the gathered ip to connect to the Virtual Machine, create some files, stop and restart the Virtual Machine with virtctl and check how data persists.

```
ssh fedora@VM_IP
```

This concludes this section of the lab.

[Previous Lab]({{ site.baseurl }}/labs/kubernetes/lab1)
