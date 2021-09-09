---
layout: post
author: David Vossel
description: This blog post outlines the fundamentals for how to import VMs from AWS into KubeVirt
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "AWS",
    "EC2",
    "AMI",
  ]
comments: true
title: Import AWS AMIs as KubeVirt Golden Images
pub-date: September 21
pub-year: 2021
---

## Breaking Out

There comes a point where an operations team has invested so heavily in a Iaas platform that they are effectively locked into that platform. For example, here's one scenario outlining how this can happen. An operations team has created automation around building VM images and keeping images up-to-date. In AWS that automation likely involves starting an EC2 instance, injecting some application logic into that instance, sealing the instance's boot source as an AMI, and finally copying that AMI around to all the AWS regions the team deploys in.

If the team was interested in evaluating KubeVirt as an alternative Iaas platform to AWS's EC2, given the team's existing tooling there's not a clear path for doing this. It's that scenario where the tooling in the [kubevirt-cloud-import](https://github.com/davidvossel/kubevirt-cloud-import) project comes into play.

## Kubevirt Cloud Import

The [KubeVirt Cloud Import](https://github.com/davidvossel/kubevirt-cloud-import) project explores the practicality of transitioning VMs from various cloud providers into KubeVirt. As of writing this, automation for exporting AMIs from EC2 into KubeVirt works, and it's really not all that complicated.

This blog post will explore the fundamentals of how AMIs are exported, and how the KubeVirt Cloud Import project leverages these techniques to build automation pipelines.

## Nuts and Bolts of Importing AMIs

### Official AWS AMI Export Support

AWS supports an [api](https://docs.aws.amazon.com/vm-import/latest/userguide/vmexport_image.html) for exporting AMIs as a file to an s3 bucket. This support works quite well, however there's a long list of [limitations](https://docs.aws.amazon.com/vm-import/latest/userguide/vmexport_image.html#limits-image-export) that impact what AMIs are eligible for export. The most limiting of those items is the one that prevents any image built from an AMI on the marketplace from being eligible for the official export support.

### Unofficial AWS export Support

Regardless of what AWS officially supports or not, there's absolutely nothing preventing someone from exporting an AMI's contents themselves. The technique just involves creating an EC2 instance, attaching an EBS volume (containing the AMI contents) as a block device, then streaming that block devices contents where ever you want.

Theoretically, the steps roughly look like this.

* Convert AMI to a volume by finding the underlying AMI's snapshot and converting it to an EBS volume.
* Create an EC2 instance with the EBS volume containing the AMI contents as a secondary data device.
* Within the EC2 guest, copy the EBS device's contents as a disk img `dd if=/dev/xvda of=/tmp/disk/disk.img`
* Then upload the disk image to an object store like s3. `aws s3 cp /tmp/disk/disk.img s3://my-b1-bucket/ upload: ../tmp/disk/disk.img to s3://my-b1-bucket/disk.img`

### Basics of Importing Data into KubeVirt

Once a disk image is in s3, a KubeVirt companion project called the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer) (or CDI for short) can be used to import the disk from s3 into a PVC within the KubeVirt cluster. This import flow can be expressed as a CDI DataVolume custom resource.

Below is an example yaml for importing s3 contents into a PVC using a DataVolume

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: "example-import-dv"
spec:
  source:
      s3:
         url: "https://s3.us-west-2.amazonaws.com/my-ami-exports/kubevirt-image-exports/export-ami-0dc4e69702f74df50.vmdk"
         secretRef: "my-s3-credentials"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: "6Gi"
```

Once the AMI file content is stored in a PVC, CDI can be used further to clone that AMI's PVC on a per VM basis. This effectively recreates the AMI to EC2 relationship that exists in AWS. You can find more information about CDI [here](https://github.com/kubevirt/containerized-data-importer)

## Automating AMI import

Using the technique of exporting an AMI to an s3 bucket and importing the AMI from s3 into a KubeVirt cluster using CDI, the Kubevirt Cloud Import project provides the glue necessary for tying all of these pieces together in the form of the `import-ami` cli command and a Tekton task.

## Automation using the import-ami CLI command

The `import-ami` takes a set of arguments related to the AMI you wish to import into KubeVirt and the name of the PVC you'd like the AMI to be imported into. Upon execution, import-ami will call all the appropriate AWS and KubeVirt APIs to make this work. The result is a PVC with the AMI contents that is capable of being launched by a KubeVirt VM.

In the example below, A publicly shared [fedora34 AMI](https://alt.fedoraproject.org/cloud/) is imported into the KubeVirt cluster as a PVC called fedora34-golden-image

```bash

export S3_BUCKET=my-bucket
export S3_SECRET=s3-readonly-cred
export AWS_REGION=us-west-2
export AMI_ID=ami-00a4fdd3db8bb2851
export PVC_STORAGECLASS=rook-ceph-block
export PVC_NAME=fedora34-golden-image

import-ami --s3-bucket $S3_BUCKET --region $AWS_REGION --ami-id $AMI_ID --pvc-storageclass $PVC_STORAGECLASS --s3-secret $S3_SECRET --pvc-name $PVC_NAME

```

## Automation using the import-ami Tekton Task

In addition to the `import-ami` cli command, the KubeVirt Cloud Import project also includes a [Tekton task](https://github.com/davidvossel/kubevirt-cloud-import/blob/main/tasks/import-ami/manifests/import-ami.yaml) which wraps the cli command and allows integrating AMI import into a Tekton pipeline.

Using a Tekton pipeline, someone can combine the task of importing an AMI into KubeVirt with the task of starting a VM using that AMI. An example pipeline can be found [here](https://raw.githubusercontent.com/davidvossel/kubevirt-cloud-import/main/examples/create-vm-from-ami-pipeline.yaml) which outlines how this is accomplished.

Below is a pipeline run that uses the example pipeline to import the publicly shared fedora34 AMI into a PVC, then starts a VM using that imported AMI.

```bash

cat << EOF > pipeline-run.yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: my-vm-creation-pipeline
  namespace: default
spec:
  serviceAccountName: my-kubevirt-service-account
  pipelineRef:
    name: create-vm-pipeline 
  params:
    - name: vmName
      value: vm-fedora34
    - name: s3Bucket
      value: my-kubevirt-exports
    - name: s3ReadCredentialsSecret
      value: my-s3-read-only-credentials
    - name: awsRegion
      value: us-west-2
    - name: amiId 
      value: ami-00a4fdd3db8bb2851
    - name: pvcStorageClass 
      value: rook-ceph-block
    - name: pvcName
      value: fedora34
    - name: pvcNamespace
      value: default
    - name: pvcSize
      value: 6Gi
    - name: pvcAccessMode
      value: ReadWriteOnce
    - name: awsCredentialsSecret
      value: my-aws-credentials
EOF

kubectl create -f pipeline-run.yaml
```

After posting the pipeline run, watch for the pipeline run to complete.

```bash
$ kubectl get pipelinerun
selecting docker as container runtime
NAME                      SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
my-vm-creation-pipeline   True        Succeeded   11m         9m54s
```

Then observe that the resulting VM is online

```bash
$ kubectl get vmi
selecting docker as container runtime
NAME          AGE   PHASE     IP               NODENAME   READY
vm-fedora34   11m   Running   10.244.196.175   node01     True
```

For more detailed and up-to-date information about how to automate AMI import using Tekton, view the KubeVirt Cloud Import [README.md](https://github.com/davidvossel/kubevirt-cloud-import/blob/main/README.md)

## Key Takeaways

The portability of workloads across different environments is becoming increasingly important and operations teams need to be vigilant about avoiding vendor lock in. For containers, Kubernetes is an attractive option because it provides a consistent API layer that can run across multiple cloud platforms. KubeVirt can provide that same level of consistency for VMs. As a community we need to invest further into automation tools that allow people to make the transition to KubeVirt.
