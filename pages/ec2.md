---
layout: page
title: Try KubeVirt on AWS
---

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

| EC2 Region | Location      | AMI Type | AMI ID |
| ---        | ---           | ---      | ---    |
|            |               |          |        |
| us-east-1  | N. Virginia   | HVM      | [ami-0050c59eb4514da3e](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0050c59eb4514da3e){:target="_blank"} |
| us-east-2  | Ohio          | HVM      | [ami-0e40bbe9e87f726cd](https://console.aws.amazon.com/ec2/home?region=us-east-2#launchAmi=ami-0e40bbe9e87f726cd){:target="_blank"} |
| us-west-1  | N. California | HVM      | [ami-02ab6c92f0c112fd7](https://console.aws.amazon.com/ec2/home?region=us-west-1#launchAmi=ami-02ab6c92f0c112fd7){:target="_blank"} |
| us-west-2  | Oregon        | HVM      | [ami-0d279ebc148a4f36c](https://console.aws.amazon.com/ec2/home?region=us-west-2#launchAmi=ami-0d279ebc148a4f36c){:target="_blank"} |
|            |               |          |        |
| ca-central-1 | Canada   | HVM      | [ami-0e377c951874e2bf7](https://console.aws.amazon.com/ec2/home?region=ca-central-1#launchAmi=ami-0e377c951874e2bf7){:target="_blank"} |
|            |               |          |        |
| eu-west-1      | Ireland   | HVM      | [ami-0bb04bf9edc84cade](https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-0bb04bf9edc84cade){:target="_blank"} |
| eu-west-2      | London    | HVM      | [ami-0a94f7993db846173](https://console.aws.amazon.com/ec2/home?region=eu-west-2#launchAmi=ami-0a94f7993db846173){:target="_blank"} |
| eu-west-3      | Paris    | HVM      | [ami-03eded124bfcbf774](https://console.aws.amazon.com/ec2/home?region=eu-west-3#launchAmi=ami-03eded124bfcbf774){:target="_blank"} |
| eu-central-1   | Frankfurt | HVM      | [ami-023bfd05de1c68da3](https://console.aws.amazon.com/ec2/home?region=eu-central-1#launchAmi=ami-023bfd05de1c68da3){:target="_blank"} |
|                |               |          |        |
| ap-northeast-1 | Tokyo   | HVM      | [ami-031a9f9bb5116ed8e](https://console.aws.amazon.com/ec2/home?region=ap-northeast-1#launchAmi=ami-031a9f9bb5116ed8e){:target="_blank"} |
| ap-southeast-1 | Singapore | HVM      | [ami-04422eec3514f1e87](https://console.aws.amazon.com/ec2/home?region=ap-southeast-1#launchAmi=ami-04422eec3514f1e87){:target="_blank"} |
| ap-southeast-2 | Sydney   | HVM      | [ami-0c8d2e1ad2031cecc](https://console.aws.amazon.com/ec2/home?region=ap-southeast-2#launchAmi=ami-0c8d2e1ad2031cecc){:target="_blank"} |
| ap-south-1     | Mumbai   | HVM      | [ami-08e83860b87a12816](https://console.aws.amazon.com/ec2/home?region=ap-south-1#launchAmi=ami-08e83860b87a12816){:target="_blank"} |
|            |               |          |        |
| sa-east-1  | Sao Paulo   | HVM      | [ami-06baa167dc17800eb](https://console.aws.amazon.com/ec2/home?region=sa-east-1#launchAmi=ami-06baa167dc17800eb){:target="_blank"} |
|            |               |          |        |


 * At the instance type selection screen, select a type that has at least
   4GB of memory. This is the minimum amount of memory required to complete
   the labs in Step 2. Select more memory or storage if you are planning
   to deploy VMs with larger memory or storage requirements than what is
   used in the labs.

![instance-type-memory-selection](/assets/images/kubevirt-button/ec2-instance-memory-selection.png)

 * We install Weave Net as the CNI to enable pods to communicate with each
   other in the Kubernetes cluster. We reserve the 172.30.0.0/16 IP allocation
   range for Weave Net. Verify that the VPC you selected for "Network" in the
   "Instance Details" screen has a CIDR that does not overlap with Weave's
   IP allocation range.

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
