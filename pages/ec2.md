---
layout: page
title: Easy install using AWS 
---

We have created AWS images that automatically install Kubernetes
and KubeVirt inside an EC2 instance to help you quickly deploy 
a trial environment. These images are not meant to be used in 
production.

To use the images, you should already have an AWS account. The images 
are free to use but AWS will bill you for instance hours, storage,
 and associated services unless you are in an AWS trial period.

## Step 1: Launch KubeVirt in Amazon EC2

Click on an AMI link below to start up an instance in your preferred
EC2 region.

At least 4GB of memory is required to complete the tutorial.
Select more instance memory and storage if you are planning to deploy 
VMs with larger memory and storage requirements.

When configuring your instance, you will also need to allow ingress 
to SSH and select a key pair to SSH into your instance.

| EC2 Region | Location      | AMI Type | AMI ID |
| ---        | ---           | -------- | ---:    |
|            |               |          |        |
| us-east-1  | N. Virginia   | HVM      | [ami-0bbcf719fec0d74e9](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0bbcf719fec0d74e9) |
| us-east-2  | Ohio          | HVM      | [ami-044aa283a41e6ef37](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-044aa283a41e6ef37) |
| us-west-1  | N. California | HVM      | [ami-0c14ec087d17f9012](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0c14ec087d17f9012) |
| us-west-2  | Oregon        | HVM      | [ami-08190196d0f8271ca](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-08190196d0f8271ca) |
|            |               |          |        |
| ca-central-1 | Canada   | HVM      | [ami-00bb805a6b82e11ab](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-00bb805a6b82e11ab) |
|            |               |          |        |
| eu-west-1      | Ireland   | HVM      | [ami-01e0fa09440c6610f](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-01e0fa09440c6610f) |
| eu-west-2      | London    | HVM      | [ami-05cb85ccf49452dd3](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-05cb85ccf49452dd3) |
| eu-west-3      | Paris    | HVM      | [ami-06f30cf3c97215d50](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-06f30cf3c97215d50) |
| eu-central-1   | Frankfurt | HVM      | [ami-0439bc95ea180e33d](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0439bc95ea180e33d) |
|                |               |          |        |
| ap-northeast-1 | Tokyo   | HVM      | [ami-03339e0ccdafb2bc9](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-03339e0ccdafb2bc9) |
| ap-southeast-1 | Singapore | HVM      | [ami-006e3a928020bebb9](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-006e3a928020bebb9) |
| ap-southeast-2 | Sydney   | HVM      | [ami-047df916b259b17cf](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-047df916b259b17cf) |
| ap-south-1     | Mumbai   | HVM      | [ami-0bbcf719fec0d74e9](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0bbcf719fec0d74e9) |
|            |               |          |        |
| sa-east-1  | Sao Paulo   | HVM      | [ami-0447be57cacc2bff4](https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-0447be57cacc2bff4) |
|            |               |          |        |

It takes about 5 mins after the EC2 instance is started for the 
instance to be ready for SSH login.

## Step 2: Walkthrough the KubeVirt labs

After you have connected to your instance, you can walkthrough
a couple of labs to help you get acquainted with KubeVirt and
how to use it to create and deploy VMs with Kubernetes.

The first lab is ["Use KubeVirt"](../labs/kubernetes/lab6).

The second lab is ["Experiment with CDI"](../labs/kubernetes/lab7).
