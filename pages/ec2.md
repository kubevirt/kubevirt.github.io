---
layout: labs
title: Easy install using AWS
permalink: pages/ec2
lab: kubernetes
order: 1
---

# Easy install using AWS

We have created AWS images that automatically install Kubernetes
and KubeVirt inside an EC2 instance to help you quickly deploy
a trial environment.

In Step 1, we guide you through selecting an AMI and some factors to
consider when launching the EC2 instance through the AWS console.

After you have launched your EC2 instance, navigate back to this
page and then dive into the two labs below to help you get
acquainted with KubeVirt.

## Step 1: Launch KubeVirt in Amazon EC2

To use the images in the table below, you should already have an AWS
account. The images are free to use but AWS will bill you for instance
hours, storage, and associated services unless you are in an AWS trial
period. These images are not meant to be used in production.

 * First, open one of the AMI links below in a new tab or window to start up an instance in your preferred
   EC2 region.

| EC2 Region | AMI Type | AMI ID |
| - | - | - |
{% for ami in site.data.amis %} | {{ ami.region }} | HVM | [{{ ami.ami_id }}](https://console.aws.amazon.com/ec2/home?region={{ ami.region }}#launchAmi={{ ami.ami_id }}){:target="_blank"} |
{% endfor %}

 * At the instance type selection screen, select a type that has at least
   4GB of memory. This is the minimum amount of memory required to complete
   the labs in Step 2. Select more memory or storage if you are planning
   to deploy VMs with larger memory or storage requirements than what is
   used in the labs.

![instance-type-memory-selection](/assets/images/kubevirt-button/ec2-instance-memory-selection.png)

 * You will need to be able to log into your instance through SSH. Depending
   on your network configuration, you may need to enable public IP. To enable
   a public IP, in the "Instance Details" screen select "Enable" for
   "Auto-assign Public IP" or select "Use subnet setting" if public IPs
   are enabled for your subnet.

![instance-enable-public-ip](/assets/images/kubevirt-button/ec2-public-ip.png)

 * At the security group configuration screen, allow ingress to SSH by
   enabling access to port 22 from your IP address.

 ![instance-enable-public-ip](/assets/images/kubevirt-button/ec2-ssh-ingress.png)

 * Finally, you will need to associate a key pair with your instance. If
   you have created one before, select it. If haven't created one before,
   select "Create a new key pair", enter a name, download the private key,
   and note where you place it because you will use it in a few minutes.
   Once you made your selection, hit "Launch Instance". It takes about
   5 mins after the EC2 instance is started for the instance to be ready
   for SSH login.

  ![instance-enable-public-ip](/assets/images/kubevirt-button/ec2-select-create-keypair.png)

 * Once your instance is ready, SSH to your EC2 instance using your private
   key. Note "centos" is the default username.

```bash
ssh -i <aws-private-key> centos@<ec2_public_ip_or_hostname>

```

## Step 2: KubeVirt labs

After you have connected to your instance through SSH, you can
work through a couple of labs to help you get acquainted with KubeVirt
and how to use it to create and deploy VMs with Kubernetes.

The first lab is ["Use KubeVirt"](../labs/kubernetes/lab1). This lab walks you
through the creation of a Virtual Machine instance on Kubernetes and then
shows you how to use virtctl to interact with its console.

The second lab is ["Experiment with CDI"](../labs/kubernetes/lab2). This
lab shows you how to use the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer){:target="_blank"}
(CDI) to import a VM image into a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/){:target="_blank"}
(PVC) and then how to define a VM to make use of the PVC.

## Found a bug?

We are interested in hearing about your experience.

If you encounter an issue with deploying your cloud instance or if
Kubernetes or KubeVirt did not install correctly, please report it to
the [cloud-image-builder issue tracker](https://github.com/kubevirt/cloud-image-builder/issues){:target="_blank"}.

If experience a problem with the labs, please report it to the [kubevirt.io issue tracker](https://github.com/kubevirt/kubevirt.github.io/issues){:target="_blank"}.
