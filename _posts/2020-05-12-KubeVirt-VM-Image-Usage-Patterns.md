---
layout: post
author: David Vossel
description: This blog post outlines methods for building and using virtual machine images with KubeVirt
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "images",
    "storage",
  ]
comments: true
title: KubeVirt VM Image Usage Patterns
pub-date: May 12
pub-year: 2020
---

# Building a VM Image Repository

You know what I hear a lot from new KubeVirt users?

> "How do I manage VM images with KubeVirt? There’s a million options and I have no idea where to start."

And I agree. It’s not obvious. There are a million ways to use and manipulate VM images with KubeVirt. That’s by design. KubeVirt is meant to be as flexible as possible, but in the process I think we dropped the ball on creating some well defined workflows people can use as a starting point.

So, that’s what I’m going to attempt to do. I’ll show you how to make your images accessible in the cluster. I’ll show you how to make a custom VM image repository for use within the cluster. And I’ll show you how to use this at scale using the same patterns you may have used in AWS or GCP.

The pattern we’ll use here is...
1. Import a base VM image into the cluster as an PVC
2. Use KubeVirt to create a new immutable custom image with application assets
3. Scale out as many VMIs as we’d like using the pre-provisioned immutable custom image.

**Remember, this isn’t “the definitive" way of managing VM images in KubeVirt. This is just an example workflow to help people get started.**

## Importing a Base Image

Let’s start with importing a base image into a PVC.

For our purposes in this workflow, the base image is meant to be immutable. No VM will use this image directly, instead VMs spawn with their own unique copy of this base image. Think of this just like you would containers. A container image is immutable, and a running container instance is using a copy of an image instead of the image itself.

### Step 0. Install KubeVirt with CDI

I’m not covering this. Use our documentation linked to below. Understand that CDI (containerized data importer) is the tool we’ll be using to help populate and manage PVCs.

[Installing KubeVirt](https://kubevirt.io/user-guide/#/installation/installation)
[Installing CDI](https://kubevirt.io/user-guide/#/installation/image-upload?id=install-cdi)

### Step 1. Create a namespace for our immutable VM images.

We’ll give users the ability to clone VM images living on PVCs from this namespace to their own namespace, but not directly create VMIs within this namespace.

```sh
kubectl create namespace vm-images
```

### Step 2. Import your image to a PVC in the image namespace

Below are a few options for importing. For each example, I’m using the Fedora Cloud qcow2 image that can be downloaded [here](https://download.fedoraproject.org/pub/fedora/linux/releases/31/Cloud/x86_64/images/Fedora-Cloud-Base-31-1.9.x86_64.qcow2)

If you try these examples yourself, you’ll need to download the **Fedora-Cloud-Base-31-1.9.x86_64.qcow2** image file in your working directory.

**Example: Import a local VM from your desktop environment using virtctl**

If you don’t have ingress setup for the cdi-uploadproxy service endpoint (which you don’t if you’re reading this) we can set up a local port forward using kubectl. That gives a route into the cluster to upload the image. Leave the command below executing to open the port.

```sh
kubectl port-forward -n cdi service/cdi-uploadproxy 18443:443
```

In a separate terminal upload the image over the port forward connection using the virtctl tool. Note that the size of the PVC must be the size of what the qcow image will expand to when converted to a raw image. In this case I chose 5 gigabytes as the PVC size.

```sh
virtctl image-upload dv fedora-cloud-base-31 --namespace vm-images  --size=5Gi --image-path Fedora-Cloud-Base-31-1.9.x86_64.qcow2  --uploadproxy-url=https://127.0.0.1:18443 --insecure
```

Once that completes, you’ll have a PVC in the vm-images namespace that contains the Fedora Cloud image.

```sh
kubectl get pvc -n vm-images
NAME               STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fedora-cloud-base-31   Bound    local-pv-e824538e   5Gi       RWO            local          60s
```

**Example: Import using a container registry**

If the image’s footprint is small like our Fedora Cloud Base qcow image, then it probably makes sense to use a container image registry to import our image from a container image to a PVC.

In the example below, I start by building a container image with the Fedora Cloud Base qcow VM image in it, and push that container image to my container registry.

```sh
cat << END > Dockerfile
FROM scratch
ADD Fedora-Cloud-Base-31-1.9.x86_64.qcow2 /disk/
END
docker build -t quay.io/dvossel/fedora:cloud-base-31 .
docker push quay.io/dvossel/fedora:cloud-base-31
```

Next a CDI DataVolume is used to import the VM image into a new PVC from the container image you just uploaded to your container registry. Posting the DataVolume manifest below will result in a new 5 gigabyte PVC being created and the VM image being placed on that PVC in a way KubeVirt can consume it.

```sh
cat << END > fedora-cloud-base-31-datavolume.yaml
apiVersion: cdi.kubevirt.io/v1alpha1
kind: DataVolume
metadata:
  name: fedora-cloud-base-31
  namespace: vm-images
spec:
  source:
    registry:
      url: "docker://quay.io/dvossel/fedora:cloud-base-31"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 5Gi
END
kubectl create -f fedora-cloud-base-31-datavolume.yaml
```

You can observe the CDI complete the import by watching the DataVolume object.

```sh
kubectl describe datavolume fedora-cloud-base-31 -n vm-images
.
.
.
Status:
  Phase:     Succeeded
  Progress:  100.0%
Events:
  Type    Reason            Age                   From                   Message
  ----    ------            ----                  ----                   -------
  Normal  ImportScheduled   2m49s                 datavolume-controller  Import into fedora-cloud-base-31 scheduled
  Normal  ImportInProgress  2m46s                 datavolume-controller  Import into fedora-cloud-base-31 in progress
  Normal  Synced            40s (x11 over 2m51s)  datavolume-controller  DataVolume synced successfully
  Normal  ImportSucceeded   40s                   datavolume-controller  Successfully imported into PVC fedora-cloud-base-31
```

Once the import is complete, you’ll see the image available as a PVC in your vm-images namespace. The PVC will have the same name given to the DataVolume.

```sh
kubectl get pvc -n vm-images
NAME                   STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fedora-cloud-base-31   Bound    local-pv-e824538e   5Gi       RWO            local          60s
```

**Example: Import an image from an http or s3 endpoint**

While I’m not going to provide a detailed example here, another option for importing VM images into a PVC is to host the image on an http server (or as an s3 object) and then use a DataVolume to import the VM image into the PVC from a URL.

Replace the url in this example with one hosting the qcow2 image. More information about this import method can be found [here](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/datavolumes.md#https3registry-source).

```sh
kind: DataVolume
metadata:
  name: fedora-cloud-base-31
  namespace: vm-images
spec:
  source:
    http:
      url: http://your-web-server-here/images/Fedora-Cloud-Base-31-1.9.x86_64.qcow2
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 5Gi
```

## Provisioning New Custom VM Image

The base image itself isn’t that useful to us. Typically what we really want is an immutable VM image preloaded with all our application related assets. This way when the VM boots up, it already has everything it needs pre-provisioned. The pattern we’ll use here is to provision the VM image once, and then use clones of the pre-provisioned VM image as many times as we’d like.

For this example, I want a new immutable VM image preloaded with an nginx webserver. We can actually describe this entire process of creating this new VM image using the single VM manifest below. Note that I’m starting the VM inside the vm-images namespace. This is because I want the resulting VM image’s cloned PVC to remain in our vm-images repository namespace.

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: nginx-provisioner
  name: nginx-provisioner
  namespace: vm-images
spec:
  runStrategy: "RerunOnFailure"
  template:
    metadata:
      labels:
        kubevirt.io/vm: nginx-provisioner
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
          - disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 1Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: fedora-31-nginx
        name: datavolumedisk1
      - cloudInitNoCloud:
          userData: |
            #!/bin/sh
            yum install -y nginx
            systemctl enable nginx
            # removing instances ensures cloud init will execute again after reboot
            rm -rf /var/lib/cloud/instances
            shutdown now
        name: cloudinitdisk
  dataVolumeTemplates:
  - metadata:
      name: fedora-31-nginx
    spec:
      pvc:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
      source:
        pvc:
          namespace: vm-images
          name: fedora-cloud-base-31
```

There are a few key takeaways from this manifest worth discussing.

1. Usage of **runStrategy: "RerunOnFailure"**. This tells KubeVirt to treat the VM's execution similar to a Kubernetes Job. We want the VM to continue retrying until the VM guest shuts itself down gracefully.
2. Usage of the **cloudInitNoCloud volume**. This volume allows us to inject a script into the VM's startup procedure. In our case, we want this script to install nginx, configure nginx to launch on startup, and then immediately shutdown the guest gracefully once that is complete.
3. Usage of the **dataVolumeTemplates section**. This allows us to define a new PVC which is a clone of our fedora-cloud-base-31 base image. The resulting VM image attached to our VM will be a new image pre-populated with nginx.

After posting the VM manifest to the cluster, wait for the corresponding VMI to reach the Succeeded phase.

```sh
kubectl get vmi -n vm-images
NAME                AGE     PHASE       IP            NODENAME
nginx-provisioner   2m26s   Succeeded   10.244.0.22   node01
```

This tells us the VM successfully executed the cloud-init script which installed nginx and shut down the guest gracefully. A VMI that never shuts down or repeatedly fails means something is wrong with the provisioning.

All that’s left now is to delete the VM and leave the resulting PVC behind as our immutable artifact. We do this by deleting the VM using the --cascade=false option. This tells Kubernetes to delete the VM, but leave behind anything owned by the VM. In this case we’ll be leaving behind the PVC that has nginx provisioned on it.

```sh
kubectl delete vm nginx-provisioner -n vm-images --cascade=false
```

After deleting the VM, you can see the nginx provisioned PVC in your vm-images namespace.

```sh
kubectl get pvc -n vm-images
NAME               STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
fedora-cloud-base-31   Bound    local-pv-e824538e   5Gi       RWO            local          60s
fedora-31-nginx            Bound    local-pv-8dla23ds    5Gi       RWO            local          60s
```

## Understanding the VM Image Repository
At this point we have a namespace, vm-images, that contains PVCs with our VM images on them. Those PVCs represent VM images in the same way AWS's AMIs represent VM images and this **vm-images namespace is our VM image repository.**

Using CDI's i[cross namespace cloning feature](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/clone-datavolume.md#how-to-clone-an-image-from-one-dv-to-another-one), VM's can now be launched across multiple namespaces throughout the entire cluster using the PVCs in this “repository". Note that non-admin users need a special RBAC role to allow for this cross namespace PVC cloning. Any non-admin user who needs the ability to access the vm-images namespace for PVC cloning will need the RBAC permissions outlined [here](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/RBAC.md#pvc-cloning).

Below is an example of the RBAC necessary to enable cross namespace cloning from the vm-images namespace to the default namespace using the default service account. 

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cdi-cloner
rules:
- apiGroups: ["cdi.kubevirt.io"]
  resources: ["datavolumes/source"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-cdi-cloner
  namespace: vm-images
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
roleRef:
  kind: ClusterRole
  name: cdi-cloner
  apiGroup: rbac.authorization.k8s.io
```

# Horizontally Scaling VMs Using Custom Image

Now that we have our immutable custom VM image, we can create as many VMs as we want using that custom image.

## Example: Scale out VMI instances using the custom VM image.

Clone the custom VM image from the vm-images namespace into the namespace the VMI instances will be running in as a **ReadOnlyMany** PVC. This will allow concurrent access to a single PVC.

```yaml
apiVersion: cdi.kubevirt.io/v1alpha1
kind: DataVolume
metadata:
  name: nginx-rom
  namespace: default
spec:
  source:
    pvc:
      namespace: vm-images
      name: fedora-31-nginx
  pvc:
    accessModes:
      - ReadOnlyMany
    resources:
      requests:
        storage: 5Gi
```

Next, create a VirtualMachineInstanceReplicaSet that references the nginx-rom PVC as an ephemeral volume. With an ephemeral volume, KubeVirt will mount the PVC read only, and use a cow (copy on write) [ephemeral volume](https://kubevirt.io/user-guide/#/creation/disks-and-volumes?id=ephemeral) on local storage to back each individual VMI. This ephemeral data’s life cycle is limited to the life cycle of each VMI.

Here’s an example manifest of a VirtualMachineInstanceReplicaSet starting 5 instances of our nginx server in separate VMIs.

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceReplicaSet
metadata:
  labels:
    kubevirt.io/vmReplicaSet: nginx
  name: nginx
spec:
  replicas: 5
  template:
    metadata:
      labels:
        kubevirt.io/vmReplicaSet: nginx
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: nginx-image
          - disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 1Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - ephemeral:
        name: nginx-image
          persistentVolumeClaim:
            claimName: nginx-rom
      - cloudInitNoCloud:
          userData: |
            # add any custom logic you want to occur on startup here.
            echo “cloud-init script execution"
        name: cloudinitdisk
```

## Example: Launching a Single “Pet" VM from Custom Image

In the manifest below, we’re starting a new VM with a PVC cloned from our pre-provisioned VM image that contains the nginx server. When the VM boots up, a new PVC will be created in the VM's namespace that is a clone of the PVC referenced in our vm-images namespace.

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: nginx
  name: nginx
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: nginx
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
          - disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 1Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: nginx
        name: datavolumedisk1
      - cloudInitNoCloud:
          userData: |
            # add any custom logic you want to occur on startup here.
            echo “cloud-init script execution"
        name: cloudinitdisk
  dataVolumeTemplates:
  - metadata:
      name: nginx
    spec:
      pvc:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
      source:
        pvc:
          namespace: vm-images
          name: fedora-31-nginx
```

# Other Custom Creation Image Tools

In my example I imported a VM base image into the cluster and used KubeVirt to provision a custom image with a technique that used cloud-init. This may or may not make sense for your use case. It’s possible you need to pre-provision the VM image before importing into the cluster at all.

If that’s the case, I suggest looking into two tools.

[Packer.io using the qemu builder](https://packer.io/docs/builders/qemu.html). This allows you to automate building custom images on your local machine using configuration files that describe all the build steps. I like this tool because it closely matches the Kubernetes "declarative" approach. 

[Virt-customize](http://libguestfs.org/virt-customize.1.html) is a cli tool that allows you to customize local VM images by injecting/modifying files on disk and installing packages.

[Virt-install](https://linux.die.net/man/1/virt-install) is a cli tool that allows you to automate a VM install as if you were installing it from a cdrom. You’ll want to look into using a kickstart file to fully automate the process.

The resulting VM image artifact created from any of these tools can then be imported into the cluster in the same way we imported the base image earlier in this document.

