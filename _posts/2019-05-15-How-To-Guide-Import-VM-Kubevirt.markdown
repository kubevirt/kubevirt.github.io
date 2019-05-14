---
layout: post
author: DirectedSoul
description: Import a VM into the Kubernetes Platform using CDI
navbar_active: Blogs
pub-date: May 20
pub-year: 2019
category: news
---

# Import a VM into the Kubernetes Native Environment:

In this BlogPost we will discuss about the VM as a yaml template and steps on how to import it as a [PVC](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) onto your kubernetes environment using the CDI and kubevirt add-ons.

**Assumptions:**

- User is familiar with the [Kubernetes-architecture](https://www.aquasec.com/wiki/display/containers/Kubernetes+Architecture+101)

- User is familiar with the concept of a [virsh based VM](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-guest_virtual_machine_installation_overview-creating_guests_with_virt_install)

- User is familiar with the [Persistent Volume(PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and [Persistent Volume Claim(PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

- User is familiar with the concept of [kubevirt-architecture](https://github.com/kubevirt/kubevirt/blob/master/docs/architecture.md) and [CDI-architecture](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/design.md#design)

**Virtual machines:**

VirtualMachine
An VirtualMachine provides additional management capabilities to a VirtualMachineInstance inside the cluster. That includes:

- ABI stability

- Start/stop/restart capabilities on the controller level

- Offline configuration change with propagation on VirtualMachineInstance recreation

- Ensure that the VirtualMachineInstance is running if it should be running

It focuses on a 1:1 relationship between the controller instance and a virtual machine instance. In many ways it is very similar to a StatefulSet with spec.replica set to 1.

**How to use a VirtualMachine:**

A VirtualMachine will make sure that a VirtualMachineInstance object with an identical name will be present in the cluster, if spec.running is set to true. Further it will make sure that a VirtualMachineInstance will be removed from the cluster if spec.running is set to false.

There exists a field spec.runStrategy which can also be used to control the state of the associated VirtualMachineInstance object. To avoid confusing and contradictory states, these fields are mutually exclusive. An extended explanation of spec.runStrategy vs spec.running can be found in Run Strategies.

**Starting and stopping**

After creating a VirtualMachine it can be switched on or off like this:
```shell
# Start the virtual machine:
virtctl start myvm

# Stop the virtual machine:
virtctl stop myvm
```
Kubectl can be used for the same:

```shell
# Start the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

# Stop the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'
```
**VM defined in a `yaml` format:**

In genaral, VM's can be defined as a `yaml` manifests and can be deployed as k8s objects, a simple example of a VM  in a yaml format is below:

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-cirros
  name: vm-cirros
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-cirros
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 64M
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: kubevirt/cirros-container-disk-demo:latest
      - cloudInitNoCloud:
          userDataBase64: IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        name: cloudinitdisk

```
From the above manifest, `kind: VirtualMachine` states that its a VM object, `spec` section has pvc request as a local storage, `source` refering to the http url where the `iso` of a VM is stored. In the later section of this Blog you will see how this is all gets connected in the context of CDI. 

# **Note**: 

- More examples of a VM declared as a `yaml` manifest can be seen [here](https://github.com/kubevirt/kubevirt/tree/master/cluster/examples)

- Please feel free to take a look at how to deploy VM as a K8s object by using kubevirt add-on using minikube [here](https://kubevirt.io//quickstart_minikube/)

For detailed usage of Volumes, you can take a look at [here](https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/disks-and-volumes.html)

Now, we have seen how a VM can be declared as a yaml object inside kubernetes, we will now see how CDI and kubevirt help in getting our VM workload into the cluster.Next immediate question that comes to our mind is "How to use a Virtual Machine in my k8s cluster?", ok, lets see how all of this is made possible.

A VirtualMachine will make sure that a VirtualMachineInstance object with an identical name will be present in the cluster, if `spec.running` is set to `true`. Further it will make sure that a VirtualMachineInstance will be removed from the cluster if `spec.running` is set to `false`.

There exists a field `spec.runStrategy` which can also be used to control the state of the associated VirtualMachineInstance object. To avoid confusing and contradictory states, these fields are mutually exclusive. An extended explanation of `spec.runStrategy` vs `spec.running` can be found in [Run Strategies](https://kubevirt.io/user-guide/docs/latest/architecture/creating-virtual-machines/run-strategies.html).

Saving this manifest into vm.yaml and submitting it to Kubernetes will create the controller instance:

```shell
$ kubectl create -f vm.yaml
virtualmachine "vm-cirros" created
```
Since spec.running is set to false, no vmi will be created:

```shell
$ kubectl get vmis
No resources found.
```
Let’s start the VirtualMachine:

```shell
$ virtctl start omv vm-cirros
```

As expected, a VirtualMachineInstance called vm-cirros got created:
```shell
$ kubectl describe vm vm-cirros
Name:         vm-cirros
Namespace:    default
Labels:       kubevirt.io/vm=vm-cirros
Annotations:  <none>
API Version:  kubevirt.io/v1alpha3
Kind:         VirtualMachine
Metadata:
  Cluster Name:
  Creation Timestamp:  2019-05-14T09:25:08Z
  Generation:          0
  Resource Version:    6418
  Self Link:           /apis/kubevirt.io/v1alpha3/namespaces/default/virtualmachines/vm-cirros
  UID:                 60043358-4c58-11e8-8653-525500d15501
Spec:
  Running:  true
  Template:
    Metadata:
      Creation Timestamp:  <nil>
      Labels:
        Kubevirt . Io / Ovmi:  vm-cirros
    Spec:
      Domain:
        Devices:
          Disks:
            Disk:
              Bus:        virtio
            Name:         containerdisk
            Volume Name:  containerdisk
            Disk:
              Bus:        virtio
            Name:         cloudinitdisk
            Volume Name:  cloudinitdisk
        Machine:
          Type:
        Resources:
          Requests:
            Memory:                      64M
      Termination Grace Period Seconds:  0
      Volumes:
        Name:  containerdisk
        Registry Disk:
          Image:  kubevirt/cirros-registry-disk-demo:latest
        Cloud Init No Cloud:
          User Data Base 64:  IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        Name:                 cloudinitdisk
Status:
  Created:  true
  Ready:    true
Events:
  Type    Reason            Age   From                              Message
  ----    ------            ----  ----                              -------
  Normal  SuccessfulCreate  15s   virtualmachine-controller  Created virtual machine: vm-cirros
```
**Note**: For more detailed explanation check the link [here](https://kubevirt.io/user-guide/docs/latest/architecture/virtual-machine.html). 

Since we were able to start and stop the VM instance, now lets shift our focus on importing the VM.

**Creating Virtual Machines from local images with CDI and virtctl:**

The [Containerized Data Importer (CDI)](https://github.com/kubevirt/containerized-data-importer) project provides facilities for enabling Persistent Volume Claims (PVCs) to be used as disks for KubeVirt VMs. The three main CDI use cases are:

- Import a disk image from a URL to a PVC (HTTP/S3)

- Clone an an existing PVC

- Upload a local disk image to a PVC

This document deals with the third use case. So you should have CDI installed in your cluster, a VM disk that you’d like to upload, and virtctl in your path.

Lets begin by installing the latest CDI release [here](https://github.com/kubevirt/containerized-data-importer/releases) (currently v1.9.0)

```shell
VERSION=v1.9.0
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator-cr.yaml
```

**Expose cdi-uploadproxy service:**

The cdi-uploadproxy service must be accessible from outside the cluster. Here are some ways to do that:

- [NodePort Service](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

- [Route](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html)

We can take a look at example manifests [here](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/upload.md)

The supported image formats are:

- .img

- .iso

- .qcow2

- Also compressed .tar, .gz and .xz of the above are supported.

This Blog uses [this](http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img) [CirrOS](https://launchpad.net/cirros) Image(in a .img format)

we can use `virtctl` command for uploading the image as shown below:

```shell
virtctl image-upload --help
Upload a VM image to a PersistentVolumeClaim.

Usage:
  virtctl image-upload [flags]

Examples:
  # Upload a local disk image to a newly created PersistentVolumeClaim:
    virtctl image-upload --upload-proxy-url=https://cdi-uploadproxy.mycluster.com --pvc-name=upload-pvc --pvc-size=10Gi --image-path=/images/fedora28.qcow2

Flags:
      --access-mode string       The access mode for the PVC. (default "ReadWriteOnce")
  -h, --help                     help for image-upload
      --image-path string        Path to the local VM image.
      --insecure                 Allow insecure server connections when using HTTPS.
      --no-create                Don't attempt to create a new PVC.
      --pvc-name string          The destination PVC.
      --pvc-size string          The size of the PVC to create (ex. 10Gi, 500Mi).
      --storage-class string     The storage class for the PVC.
      --uploadproxy-url string   The URL of the cdi-upload proxy service.
      --wait-secs uint           Seconds to wait for upload pod to start. (default 60)

Use "virtctl options" for a list of global command-line options (applies to all commands).
```

Here, `virtctl image-upload'' works by creating a PVC of the requested size, sending an `UploadTokenRequest` to the `cdi-apiserver`, and uploading the file to the `cdi-uploadproxy`.

```shell
virtctl image-upload --pvc-name=cirros-vm-disk --pvc-size=500Mi --image-path=/home/shegde/images/cirros-0.4.0-x86_64-disk.img --uploadproxy-url=<url to upload proxy service>
```
**To create a VirtualMachineInstance from a PVC:**

```shell
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: cirros-vm
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: pvcdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: pvcdisk
    persistentVolumeClaim:
      claimName: cirros-vm-disk
status: {}
EOF
```
**Connect to VirtualMachineInstance console**

Use virtctl to connect to the newly create VirtualMachinInstance.

```shell
virtctl console cirros-vm
```



