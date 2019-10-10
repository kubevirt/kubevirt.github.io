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

**NOTE**: This 'lab' targets deployment on *one node* as it uses `hostpath` storage provisioner which is randomly deployed to any node, causing that in the event of more than one nodes, only one will get the storage and that should be the node where the VM should be deployed on, otherwise, it will fail.

#### Install the CDI

We will first explore each component and install them. In this exercise we create a hostpath provisioner and storage class. Also we will deploy the CDI component using the Operator.

```bash
{% include scriptlets/lab2/01_get_storage_manifest.sh -%}
cat storage-setup.yml
{% include scriptlets/lab2/02_create_storage.sh -%}
{% include scriptlets/lab2/03_deploy_cdi_operator.sh -%}
{% include scriptlets/lab2/04_create_cdi-cr.sh -%}
```

Review the "cdi" pods that were added.

```
{% include scriptlets/lab2/05_view_cdi_pod_status.sh -%}
```

#### Use the CDI

As an example, we will import a Fedora30 Cloud Image as a PVC and launch a Virtual Machine making use of it.

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

In case of running a local minikube this is slightly different due to how Kubernetes networking works. Note that the gathered ip is an ip from the SDN network and the only server which is inside the SDN is the minikube vm itself. So, in order to ssh to the Virtual Machine vm1 you first need to ssh minikube vm and then ssh to the ip gathered. However, as you notice this is not very straightforward. Also, take into account that you will need to copy to the minikube instance the ssh private key associated with the public ssh key added to vm1_pvc.yml file previously.

```
{% include scriptlets/lab2/14_minikube_ssh_vm1.sh -%}
```

A much more straightforward method is to expose the ssh port of the vm1 as a NodePort by means of the virtctl tool already installed in [Easy install using minikube](https://kubevirt.io/quickstart_minikube/). First, expose the vm1 as and verify that the K8S object service was created successfully as NodePort on a random port of the Minikube VM.

```
{% include scriptlets/lab2/15_minikube_virtctl_expose_ssh_nodeport.sh -%}
```

Once exposed successfully, check the IP of your Minikube VM and verify you can reach the VM using your public SSH key previously configured.

```
{% include scriptlets/lab2/16_minikube_vm_ip.sh -%}
```

```
{% include scriptlets/lab2/17_ssh_from_outer_minikube.sh -%}
```


This concludes this section of the lab.

[Previous Lab]({{ site.baseurl }}/labs/kubernetes/lab1)
