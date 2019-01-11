---
layout: post
author: karmab
description: Kubevirt Autodeployer
navbar_active: Blogs
pub-date: Dic 13
pub-year: 2018
category: news
comments: true
---

# How to easily test specific versions of kubevirt on gcp

At kubevirt, we created cloud images on gcp and aws to ease evaluation of the project. It works fine, has a dedicated CI and is updated when new releases come out, but i wanted to go a little bit further and see if i could easily spawn a vm which would default to latest versions of the components, or that would allow me to test a given PR without focusing on deployment details

## So What did i come up with

the image is called `autolatest` and can be found on [Google Storage](https://console.cloud.google.com/storage/browser/kubevirt-button)

I assume that you have a Google account with an active payment method
or a free trial. You also need to make sure that you have a default keypair
installed.

From console.cloud.google.com, go to "Compute Engine", "Images" and then click
on "Create Image" or click this [link](https://console.cloud.google.com/compute/imagesAdd?){:target="_blank"}.

![screenshot0042](/assets/images/autodeployer/image.png)

Fill in the following data:

**Name:** kubevirt-autodeployer

**Family:** centos-7 (optional)

**Source:** cloud storage file

**Cloud storage file:** kubevirt-button/autolatest-v0.1.tar.gz

Then you can create a new instance based on this image.
Go to "Compute Engine", then to "VM instances", and then click on "Create instance".

![screenshot0042](/assets/images/autodeployer/instance.png)

It's recommended to select:

- the 2 CPU / 7.5GB instance
- a zone that supports the Haswell CPU Platform or newer (for nested virtualization to work), `us-central1-b` for instance

Under "boot disk", select the image that you created above.

If you want to use specific versions for any of the following components, create the corresponding metadata entry in Management/Metadata

- k8s_version
- flannel_version
- kubevirt_version
- cdi_version

![screenshot0042](/assets/images/autodeployer/metadata.png)


Now hit "Create" to start the instance.

Once vm is up, you should be able to connect and see through the presented banner which components got deployed


## What happened under the hood

When the vm boots, it executes a boot script which does the following:

- Gather metadata for the following variables
  - k8s_version
  - flannel_version
  - kubevirt_version
  - cdi_version

- If those metadata variables are not set, rely on values fetched from this [url](https://github.com/karmab/kubevirt-autodeployer/blob/master/versions.sh)

- Once those variables are set, the corresponding elements are deployed.
  - When latest or a PR number is specified for one of the components, we gather the corresponding latest release tag from the product repo and use it to deploy
  - When master or a number is specified for kubevirt, we build containers from source and deploy kubevirt with them

The full script is available [here](https://github.com/karmab/kubevirt-autodeployer/blob/master/image-files/first-boot.sh) and can be adapted to other platforms
