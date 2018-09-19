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
page and then dive into the two labs in Step 2 to help you get 
acquainted with KubeVirt. 

## Step 1: Launch KubeVirt in Amazon EC2

To use the images in the table below, you should already have an AWS 
account. The images are free to use but AWS will bill you for instance 
hours, storage, and associated services unless you are in an AWS trial 
period. These images are not meant to be used in production.

At least 4GB of memory is required to complete the labs in Step 2.
Select more instance memory or storage if you are planning to deploy 
VMs with larger memory or storage requirements than what is used in the
labs.

When configuring your instance, you will need to enable public IP, allow
 ingress to SSH, and select a key pair to SSH into your instance. It takes about 
5 mins after the EC2 instance is started for the instance to be ready 
for SSH login.

Click on an AMI link below to start up an instance in your preferred
EC2 region. 

| EC2 Region | Location      | AMI Type | AMI ID |
| ---        | ---           | ---      | ---    |
|            |               |          |        |
| us-east-1  | N. Virginia   | HVM      | [ami-0050c59eb4514da3e](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0050c59eb4514da3e) |
| us-east-2  | Ohio          | HVM      | [ami-0e40bbe9e87f726cd](https://console.aws.amazon.com/ec2/home?region=us-east-2#launchAmi=ami-0e40bbe9e87f726cd) |
| us-west-1  | N. California | HVM      | [ami-02ab6c92f0c112fd7](https://console.aws.amazon.com/ec2/home?region=us-west-1#launchAmi=ami-02ab6c92f0c112fd7) |
| us-west-2  | Oregon        | HVM      | [ami-0d279ebc148a4f36c](https://console.aws.amazon.com/ec2/home?region=us-west-2#launchAmi=ami-0d279ebc148a4f36c) |
|            |               |          |        |
| ca-central-1 | Canada   | HVM      | [ami-0e377c951874e2bf7](https://console.aws.amazon.com/ec2/home?region=ca-central-1#launchAmi=ami-0e377c951874e2bf7) |
|            |               |          |        |
| eu-west-1      | Ireland   | HVM      | [ami-0bb04bf9edc84cade](https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-0bb04bf9edc84cade) |
| eu-west-2      | London    | HVM      | [ami-0a94f7993db846173](https://console.aws.amazon.com/ec2/home?region=eu-west-2#launchAmi=ami-0a94f7993db846173) |
| eu-west-3      | Paris    | HVM      | [ami-03eded124bfcbf774](https://console.aws.amazon.com/ec2/home?region=eu-west-3#launchAmi=ami-03eded124bfcbf774) |
| eu-central-1   | Frankfurt | HVM      | [ami-023bfd05de1c68da3](https://console.aws.amazon.com/ec2/home?region=eu-central-1#launchAmi=ami-023bfd05de1c68da3) |
|                |               |          |        |
| ap-northeast-1 | Tokyo   | HVM      | [ami-031a9f9bb5116ed8e](https://console.aws.amazon.com/ec2/home?region=ap-northeast-1#launchAmi=ami-031a9f9bb5116ed8e) |
| ap-southeast-1 | Singapore | HVM      | [ami-04422eec3514f1e87](https://console.aws.amazon.com/ec2/home?region=ap-southeast-1#launchAmi=ami-04422eec3514f1e87) |
| ap-southeast-2 | Sydney   | HVM      | [ami-0c8d2e1ad2031cecc](https://console.aws.amazon.com/ec2/home?region=ap-southeast-2#launchAmi=ami-0c8d2e1ad2031cecc) |
| ap-south-1     | Mumbai   | HVM      | [ami-08e83860b87a12816](https://console.aws.amazon.com/ec2/home?region=ap-south-1#launchAmi=ami-08e83860b87a12816) |
|            |               |          |        |
| sa-east-1  | Sao Paulo   | HVM      | [ami-06baa167dc17800eb](https://console.aws.amazon.com/ec2/home?region=sa-east-1#launchAmi=ami-06baa167dc17800eb) |
|            |               |          |        |

Then SSH to your EC2 instance:

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
lab shows you how to use the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer)
(CDI) to import a VM image into a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) 
(PVC) and then how to define a VM to make use of the PVC.  
