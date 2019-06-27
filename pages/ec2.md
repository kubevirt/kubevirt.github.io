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

| EC2 Region     | Location      | AMI Type | AMI ID                                                                                                                                   |
| -------------- | ------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
|                |               |          |                                                                                                                                          |
| us-east-1      | N. Virginia   | HVM      | [ami-0a931f01389894a65](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0a931f01389894a65){:target="_blank"}      |
| us-east-2      | Ohio          | HVM      | [ami-007e7962f0221bf3f](https://console.aws.amazon.com/ec2/home?region=us-east-2#launchAmi=ami-007e7962f0221bf3f){:target="_blank"}      |
| us-west-1      | N. California | HVM      | [ami-0213abf4e045cafdc](https://console.aws.amazon.com/ec2/home?region=us-west-1#launchAmi=ami-0213abf4e045cafdc){:target="_blank"}      |
| us-west-2      | Oregon        | HVM      | [ami-0fc9402e92a34c972](https://console.aws.amazon.com/ec2/home?region=us-west-2#launchAmi=ami-0fc9402e92a34c972){:target="_blank"}      |
|                |               |          |                                                                                                                                          |
| ca-central-1   | Canada        | HVM      | [ami-0bbfb75f9c7f9cc6b](https://console.aws.amazon.com/ec2/home?region=ca-central-1#launchAmi=ami-0bbfb75f9c7f9cc6b){:target="_blank"}   |
|                |               |          |                                                                                                                                          |
| eu-west-1      | Ireland       | HVM      | [ami-0f0f1099dbf06d9ff](https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-0f0f1099dbf06d9ff){:target="_blank"}      |
| eu-west-2      | London        | HVM      | [ami-044fcec85282e0b84](https://console.aws.amazon.com/ec2/home?region=eu-west-2#launchAmi=ami-044fcec85282e0b84){:target="_blank"}      |
| eu-west-3      | Paris         | HVM      | [ami-081dee4cf5fd48a0c](https://console.aws.amazon.com/ec2/home?region=eu-west-3#launchAmi=ami-081dee4cf5fd48a0c){:target="_blank"}      |
| eu-central-1   | Frankfurt     | HVM      | [ami-0749b25ef0f69d33d](https://console.aws.amazon.com/ec2/home?region=eu-central-1#launchAmi=ami-0749b25ef0f69d33d){:target="_blank"}   |
|                |               |          |                                                                                                                                          |
| ap-northeast-1 | Tokyo         | HVM      | [ami-0ffa71b8fe2bbea6e](https://console.aws.amazon.com/ec2/home?region=ap-northeast-1#launchAmi=ami-0ffa71b8fe2bbea6e){:target="_blank"} |
| ap-southeast-1 | Singapore     | HVM      | [ami-07838d9608605f303](https://console.aws.amazon.com/ec2/home?region=ap-southeast-1#launchAmi=ami-07838d9608605f303){:target="_blank"} |
| ap-southeast-2 | Sydney        | HVM      | [ami-0b07b77fd6396deab](https://console.aws.amazon.com/ec2/home?region=ap-southeast-2#launchAmi=ami-0b07b77fd6396deab){:target="_blank"} |
| ap-south-1     | Mumbai        | HVM      | [ami-0d64d9f3c68588fb1](https://console.aws.amazon.com/ec2/home?region=ap-south-1#launchAmi=ami-0d64d9f3c68588fb1){:target="_blank"}     |
|                |               |          |                                                                                                                                          |
| sa-east-1      | Sao Paulo     | HVM      | [ami-0230216ffe2936a55](https://console.aws.amazon.com/ec2/home?region=sa-east-1#launchAmi=ami-0230216ffe2936a55){:target="_blank"}      |
|                |               |          |                                                                                                                                          |


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
