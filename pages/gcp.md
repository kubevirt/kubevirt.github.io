---
layout: page
title: Try KubeVirt on GCP
---

You can try KubeVirt in Google Cloud Platform.

Note this setup is not meant for production, it is meant to give you a
quick taste of KubeVirt's functionality.

The KubeVirt project publishes ready-to-use images on [Google Storage](https://console.cloud.google.com/storage/browser/kubevirt-button){:target="_blank"}.

We will assume that you have a Google account with an active payment method
or a free trial. You also need to make sure that you have a default keypair
installed.

## Step 1: Create a new image

From console.cloud.google.com, go to "Compute Engine", "Images" and then click
on "Create Image" or click this [link](https://console.cloud.google.com/compute/imagesAdd?){:target="_blank"}.

![screenshot0040](/assets/images/kubevirt-button/create_image.png)

Fill in the following data:

**Name:** kubevirt-button

**Family:** centos-7 (optional)

**Source:** cloud storage file

**Cloud storage file:** kubevirt-button/{{ site.kubevirt_version}}.tar.gz

## Step 2: Create a new instance using the image you created

Once the image is created, you can create a new instance based on this image.
Go to "Compute Engine", then to "VM instances", and then click on "Create instance".

![screenshot0042](/assets/images/kubevirt-button/create_instance_1.png)

It's recommended to select:

- the 2 CPU / 7.5GB instance
- a zone that supports the Haswell CPU Platform or newer (for nested virtualization to work), `us-central1-b` for instance

Under "boot disk", select the image that you created above.

Now hit "Create" to start the instance.

KubeVirt along with Kubernetes will get provisioned during boot!

You can now access the instance through ssh and launch VMs.

## Step 3: KubeVirt labs

After you have connected to your instance through SSH, you can
work through a couple of labs to help you get acquainted with KubeVirt
and how to use it to create and deploy VMs with Kubernetes.

The first lab is ["Use KubeVirt"](../labs/kubernetes/lab6). This lab walks you
through the creation of a Virtual Machine instance on Kubernetes and then
shows you how to use virtctl to interact with its console.

The second lab is ["Experiment with CDI"](../labs/kubernetes/lab7). This
lab shows you how to use the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer){:target="_blank"}
(CDI) to import a VM image into a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/){:target="_blank"}
(PVC) and then how to define a VM to make use of the PVC.

## Found a bug?

We are interested in hearing about your experience.

If you encounter an issue with deploying your cloud instance or if
Kubernetes or KubeVirt did not install correctly, please report it to
the [cloud-image-builder issue tracker](https://github.com/kubevirt/cloud-image-builder/issues){:target="_blank"}.

If experience a problem with the labs, please report it to the [kubevirt.io issue tracker](https://github.com/kubevirt/kubevirt.github.io/issues){:target="_blank"}.
