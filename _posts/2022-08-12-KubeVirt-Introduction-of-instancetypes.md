---
layout: post
author: Lee Yarwood
description: An introduction to Instancetypes and preferences in KubeVirt
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "instancetypes",
    "preferences",
    "VirtualMachine",
    "VirtualMachineInstancetype",
    "VirtualMachinePreference",
  ]
comments: true
title: Simplifying KubeVirt's `VirtualMachine` UX with Instancetypes and Preferences
pub-date: August 12 
pub-year: 2022
---

KubeVirt's [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) API contains many advanced options for tuning a virtual machine's resources and performance that go beyond what typical users need to be aware of. Users have until now been unable to simply define the storage/network they want assigned to their VM and then declare in broad terms what quality of resources and kind of performance they need for their VM. Instead, the user has to be keenly aware how to request specific compute resources alongside all of the performance tunings available on the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) API and how those tunings impact their guest’s operating system in order to get a desired result.

A common pattern for IaaS is to have abstractions separating the resource sizing and performance of a workload from the user-defined values related to launching their custom application. This pattern is evident across all the major cloud providers (also known as hyperscalers) as well as open source IaaS projects like OpenStack. AWS has [instance types](https://aws.amazon.com/ec2/instance-types/), GCP has [machine types](https://cloud.google.com/compute/docs/machine-types#custom_machine_types), Azure has [instance VM sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes), and OpenStack has [flavors](https://docs.openstack.org/nova/latest/user/flavors.html).

Let’s take AWS for example to help visualize what this abstraction enables. Launching an EC2 instance only requires a few top level arguments; the disk image, instance type, keypair, security group, and subnet: 

```bash
$ aws ec2 run-instances --image-id ami-xxxxxxxx \
                        --count 1 \
                        --instance-type c4.xlarge \
                        --key-name MyKeyPair \
                        --security-group-ids sg-903004f8 \
                        --subnet-id subnet-6e7f829e
```

When creating the EC2 instance the user doesn't define the amount of resources, what processor to use, how to optimize the performance of the instance, or what hardware to schedule the instance on. Instead, all of that information is wrapped up in that single `--instance-type c4.xlarge` CLI argument. `c4` denotes a specific performance profile version, in this case from the `Compute Optimized` family and `xlarge` denotes a specific amount of compute resources provided by the instance type, in this case 4 vCPUs, 7.5 GiB of RAM, 750 Mbps EBS bandwidth, etc.

While hyperscalers can provide predefined types with performance profiles and compute resources already assigned IaaS and virtualization projects such as OpenStack and KubeVirt can only provide the raw abstractions for operators, admins, and even vendors to then create instances of these abstractions specific to each deployment.

## Instancetype API

The recently renamed instancetype API and associated [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) aim to address this by providing KubeVirt users with a set of APIs and abstractions that allow them to make fewer choices when creating a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) while still ending up with a working, performant guest at runtime.

## VirtualMachineInstancetype

```yaml
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachineInstancetype
metadata:
  name: example-instancetype
spec:
  cpu:
    guest: 1
  memory:
    guest: 128Mi
```

KubeVirt now provides two instancetype based [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), a cluster wide [`VirtualMachineClusterInstancetype`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachineclusterinstancetype) and a namespaced [`VirtualMachineInstancetype`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachineinstancetype). These [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) encapsulate the following resource related characteristics of a [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine) through a shared [`VirtualMachineInstancetypeSpec`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachineinstancetypespec):

* [CPU](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_cpuinstancetype) : Required number of vCPUs presented to the guest
* [Memory](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_memoryinstancetype) : Required amount of memory presented to the guest
* [GPUs](http://kubevirt.io/api-reference/main/definitions.html#_v1_gpu) : Optional list of vGPUs to passthrough
* [HostDevices](http://kubevirt.io/api-reference/main/definitions.html#_v1_hostdevice): Optional list of HostDevices to passthrough
* [IOThreadsPolicy](`string`) : Optional IOThreadsPolicy to be used
* [LaunchSecurity](http://kubevirt.io/api-reference/main/definitions.html#_v1_launchsecurity): Optional LaunchSecurity to be used

Anything provided within an instancetype cannot be overridden within a [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine). For example, `CPU` and `Memory` are both required attributes of an instancetype. If a user makes any requests for `CPU` or `Memory` resources within their [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine), the instancetype will conflict and the request will be rejected.

## VirtualMachinePreference

```yaml
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachinePreference
metadata:
  name: example-preference
spec:
  devices:
    preferredDiskBus: virtio
    preferredInterfaceModel: virtio
```

KubeVirt also provides two further preference based [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), again a cluster-wide [`VirtualMachineClusterPreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachineclusterpreference) and namespaced [`VirtualMachinePreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachinepreference). These [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) encapsulate the preferred value of any remaining attributes of a [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine) required to run a given workload, again this is through a shared [`VirtualMachinePreferenceSpec`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachinepreferencespec).

Unlike instancetypes, preferences only represent the preferred values and as such can be overridden by values in the [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine) provided by the user.

## VirtualMachine{Instancetype,Preference}Matcher

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
[..]
  instancetype:
    kind: VirtualMachineInstancetype
    name: example-instancetype
  preference:
    kind: VirtualMachinePreference
    name: example-preference
[..]
```

The previous instancetype and preference CRDs are matched to a given [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine) through the use of a matcher. Each matcher consists of the following:

* Name (string): Name of the resource being referenced
* Kind (string):  Optional, defaults to the cluster wide CRD kinds of `VirtualMachineClusterInstancetype` or `VirtualMachineClusterPreference`
* RevisionName (string) : Optional, name of a [ControllerRevision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) containing a copy of the [`VirtualMachineInstancetypeSpec`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachineinstancetypespec) or [`VirtualMachinePreferenceSpec`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachinepreferencespec) taken when the [`VirtualMachine`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine) is first started.

## VirtualMachineInstancePreset Deprecation

The new instancetype API and CRDs conflict somewhat with the existing [`VirtualMachineInstancePreset`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineinstancepreset) CRD. The approach taken by the CRD has also been removed in core k8s so, as advertised on the [mailing list](https://groups.google.com/g/kubevirt-dev/c/eM7JaDV_EU8), I have started the [process of deprecating](https://github.com/kubevirt/kubevirt/pull/8069) [`VirtualMachineInstancePreset`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineinstancepreset) in favor of the Instancetype CRDs listed above.

## Examples

The following example is taken from the [KubeVirt User Guide](https://kubevirt.io/user-guide/virtual_machines/instancetypes/):

```yaml
$ cat << EOF | kubectl apply -f - 
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachineInstancetype
metadata:
  name: cmedium
spec:
  cpu:
    guest: 1
  memory:
    guest: 1Gi
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachinePreference
metadata:
  name: fedora
spec:
  devices:
    preferredDiskBus: virtio
    preferredInterfaceModel: virtio
    preferredRng: {}
  features:
    preferredAcpi: {}
    preferredSmm: {}
  firmware:
    preferredUseEfi: true
    preferredUseSecureBoot: true    
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  creationTimestamp: null
  name: fedora
spec:
  instancetype:
    name: cmedium
    kind: virtualMachineInstancetype
  preference:
    name: fedora
    kind: virtualMachinePreference
  runStrategy: Always
  template:
    metadata:
      creationTimestamp: null
    spec:
      domain:
        devices: {}
      volumes:
      - containerDisk:
          image: quay.io/containerdisks/fedora:latest
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            users:
              - name: admin
                sudo: ALL=(ALL) NOPASSWD:ALL
                ssh_authorized_keys:
                  - ssh-rsa AAAA...
        name: cloudinit
EOF
```

We can compare the original `VirtualMachine` spec with that of the running `VirtualMachineInstance` to confirm our instancetype and preferences have been applied using the following `diff` command:

```shell
$ diff --color -u <( kubectl get vms/fedora -o json | jq .spec.template.spec) <( kubectl get vmis/fedora -o json | jq .spec)
[..]
 {
   "domain": {
-    "devices": {},
+    "cpu": {
+      "cores": 1,
+      "model": "host-model",
+      "sockets": 1,
+      "threads": 1
+    },
+    "devices": {
+      "disks": [
+        {
+          "disk": {
+            "bus": "virtio"
+          },
+          "name": "containerdisk"
+        },
+        {
+          "disk": {
+            "bus": "virtio"
+          },
+          "name": "cloudinit"
+        }
+      ],
+      "interfaces": [
+        {
+          "bridge": {},
+          "model": "virtio",
+          "name": "default"
+        }
+      ],
+      "rng": {}
+    },
+    "features": {
+      "acpi": {
+        "enabled": true
+      },
+      "smm": {
+        "enabled": true
+      }
+    },
+    "firmware": {
+      "bootloader": {
+        "efi": {
+          "secureBoot": true
+        }
+      },
+      "uuid": "98f07cdd-96da-5880-b6c7-1a5700b73dc4"
+    },
     "machine": {
       "type": "q35"
     },
-    "resources": {}
+    "memory": {
+      "guest": "1Gi"
+    },
+    "resources": {
+      "requests": {
+        "memory": "1Gi"
+      }
+    }
   },
+  "networks": [
+    {
+      "name": "default",
+      "pod": {}
+    }
+  ],
   "volumes": [
     {
       "containerDisk": {
-        "image": "quay.io/containerdisks/fedora:latest"
+        "image": "quay.io/containerdisks/fedora:latest",
+        "imagePullPolicy": "Always"
       },
       "name": "containerdisk"
     },
```

## Future work

There's still plenty of work required before the API and CRDs can move from their current `alpha` version to `beta`. We have a specific [`kubevirt/kubevirt` issue tracking our progress to `beta`](https://github.com/kubevirt/kubevirt/issues/8235). As set out there and in the [KubeVirt community API Graduation Phase Expecations](https://github.com/kubevirt/community/blob/main/docs/api-graduation-guidelines.md), part of this work is to seek feedback from the wider community so please do feel free to chime in there with any and all feedback on the API and CRDs.

You can also track our work on this API through the [`area/instancetype` tag](https://github.com/kubevirt/kubevirt/labels/area%2Finstancetype) or my [personal blog](https://blog.yarwood.me.uk/tags/instancetypes/) where I will be posting [regular updates](https://blog.yarwood.me.uk/2022/07/21/kubevirt_instancetype_update_2/) and [demos](https://blog.yarwood.me.uk/2022/08/03/kubevirt_instancetype_demo_2/) for instancetypes.