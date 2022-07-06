---
layout: labs
title: Experiment with CDI
permalink: /labs/kubernetes/lab2
navbar_active: Labs
lab: kubernetes
order: 1
tags: [laboratory, importer, vm import, containerized data importer, CDI, lab]
---

# Experiment with the Containerized Data Importer (CDI)

[CDI](https://github.com/kubevirt/containerized-data-importer) is a utility designed to import Virtual Machine images for use with Kubevirt.

At a high level, a PersistentVolumeClaim (PVC) is created. A custom controller watches for importer specific claims, and when discovered, starts an import process to create a raw image named _disk.img_ with the desired content into the associated PVC.

> notes "Note"
> This 'lab' targets deployment on _one node_ as it uses Minikube and its `hostpath` storage class which can create PersistentVolumes (PVs) on only one node at a time. In production use, a StorageClass capable of ReadWriteOnce or better operation should be deployed to ensure PVs are accessible from any node.

#### Install the CDI

In this exercise we deploy the latest release of CDI using its Operator.

```bash
{% include scriptlets/lab2/03_deploy_cdi_operator.sh -%}
{% include scriptlets/lab2/04_create_cdi-cr.sh -%}
```

Check the status of the cdi CustomResource (CR) created in the previous step. The CR's Phase will change from Deploying to Deployed as the pods it deploys are created and reach the Running state.

```
{% include scriptlets/lab2/05_view_cdi_deployment.sh -%}
```

Review the "cdi" pods that were added.

```
{% include scriptlets/lab2/05_view_cdi_pod_status.sh -%}
```

#### Use CDI to Import a Disk Image

As an example, we will import a Fedora33 Cloud Image as a PVC and launch a Virtual Machine making use of it.

```bash
{% include scriptlets/lab2/06_create_fedora_cloud_instance.sh -%}
```

This will create the PVC with a proper annotation so that CDI controller detects it and launches an importer pod to gather the image specified in the _cdi.kubevirt.io/storage.import.endpoint_ annotation.

```
{% include scriptlets/lab2/07_view_pod_logs.sh -%}
```

Notice that the importer downloaded the publicly available Fedora Cloud qcow image. Once the importer pod completes, this PVC is ready for use in kubevirt.

> notes ""
> If the importer pod completes in error, you may need to retry it or specify a different URL to the fedora cloud image. To retry, first delete the importer pod and the PVC, and then recreate the PVC.
>
>```bash
> kubectl delete -f pvc_fedora.yml --wait
> kubectl create -f pvc_fedora.yml
>```

Let's create a Virtual Machine making use of it. Review the file _vm1_pvc.yml_.

```bash
{% include scriptlets/lab2/08_get_vm_manifest.sh -%}
cat vm1_pvc.yml
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

Finally, we will connect to vm1 Virtual Machine (VM) as a regular user would do, i.e. via ssh. This can be achieved by just ssh to the gathered ip in case we are **in the Kubernetes software defined network (SDN)**. This is true, if we are connected to a node that belongs to the Kubernetes cluster network. Probably if you followed the [Easy install using AWS]({% link pages/ec2.md %}) or [Easy install using GCP]({% link pages/gcp.md %}) your cloud instance is already part of the cluster.

```
{% include scriptlets/lab2/13_ssh_to_vm1.sh -%}
```

On the other side, if you followed [Easy install using minikube]({% link pages/quickstart_minikube.md %}) take into account that you will need to ssh into Minikube first, as shown below.

```
{% include scriptlets/lab2/14_minikube_ssh_vm1.sh -%}
```

Finally, on a usual situation you will probably want to give access to your vm1 VM to someone else from outside the Kubernetes cluster nodes. Someone who is actually connecting from his or her laptop. This can be achieved with the virtctl tool already installed in [Easy install using minikube]({% link pages/quickstart_minikube.md %}). **Note that this is the same case as connecting from our laptop to vm1 VM running on our local Minikube instance**

First, we are going expose the ssh port of the vm1 as NodePort type. Then verify that the Kubernetes object service was created successfully on a random port of the Minikube or cloud instance.

```
{% include scriptlets/lab2/15_minikube_virtctl_expose_ssh_nodeport.sh -%}
```

Once exposed successfully, check the IP of your Minikube VM or cloud instance and verify you can reach the VM using your public SSH key previously configured. In case of cloud instances verify that security group applied allows traffic to the random port created.

```
{% include scriptlets/lab2/16_minikube_vm_ip.sh -%}
```

```
{% include scriptlets/lab2/17_ssh_from_outer_minikube.sh -%}
```

This concludes this section of the lab.

You can watch how the laboratory is done in the following video:

<iframe width="560" height="315" style="height: 315px" src="https://www.youtube.com/embed/ZHqcHbCxzYM" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Previous Lab]({{ site.baseurl }}/labs/kubernetes/lab1)
