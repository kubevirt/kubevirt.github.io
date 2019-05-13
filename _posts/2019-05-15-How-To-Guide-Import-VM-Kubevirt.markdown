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

# **Assumptions**

- User is familiar with the [Kubernetes-architecture](https://www.aquasec.com/wiki/display/containers/Kubernetes+Architecture+101)

- User is familiar with the concept of a [virsh based VM](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-guest_virtual_machine_installation_overview-creating_guests_with_virt_install)

- User is familiar with the [Persistent Volume(PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and [Persistent Volume Claim(PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

- User is familiar with the concept of [kubevirt-architecture](https://github.com/kubevirt/kubevirt/blob/master/docs/architecture.md) and [CDI-architecture](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/design.md#design)

# VM defined in a `yaml` format 

In genaral, VM's can be defined as a `yaml` manifests and can be deployed as k8s objects, a simple example of a VM  in a yaml format is below:

```yaml
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-alpine-datavolume
  name: vm-alpine-datavolume
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: alpine-dv
    spec:
      pvc:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi
        storageClassName: local
      source:
        http:
          url: http://cdi-http-import-server.kubevirt/images/alpine.iso
    status: {}
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-alpine-datavolume
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
        machine:
          type: ""
        resources:
          requests:
            memory: 64M
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: alpine-dv
        name: datavolumedisk1
```

From the above manifest, `kind: VirtualMachine` states that its a VM object, `spec` section has pvc request as a local storage, `source` refering to the http url where the `iso` of a VM is stored. In the later section of this Blog you will see how this is all gets connected in the context of CDI. 

# **Note**: 

- More examples of a VM declared as a `yaml` manifest can be seen [here](https://github.com/kubevirt/kubevirt/tree/master/cluster/examples)

- Please feel free to take a look at how to deploy VM as a K8s object by using kubevirt add-on using minikube [here](https://kubevirt.io//quickstart_minikube/)

Best way of solving the problem of the VM import into K8s is by using Container Data Importter(CDI) functionality. 

To do that, we need to know the concept of DataVolumes: In general, DataVolumes are an abstraction of the Kubernetes resource, PVC (Persistent Volume Claim) and it also leverages other CDI features to ease the process of importing data into a K8's cluster.

DataVolumes can be defined by themselves or embedded within a VirtualMachine resource definition, the first method can be used to orchestrate events based on the DataVolume status phases while the second eases the process of providing storage for a VM.

Lets look at the sample DataVolume yaml file:

```yaml
---
apiVersion: v1
data:
  feature-gates: DataVolumes
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kube-system
---

DataVolumes are enabled through [feature-gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

Then as seen from above they are embedded inside the VM spec.

Here, You can set the disk bus type, overriding the defaults, which in turn depends on the chipset the VM is configured to use:

```yaml
metadata:
  name: datavolumedisk1
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: datavolumedisk1
        # This makes it a disk
        disk:
          # This makes it exposed as /dev/vda, being the only and thus first
          # disk attached to the VM
          bus: virtio
  volumes:
  - dataVolume:
      name: alpine-dv
    name: datavolumedisk1
``` 
For detailed usage of Volumes, you can take a look at [here](https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/disks-and-volumes.html)
