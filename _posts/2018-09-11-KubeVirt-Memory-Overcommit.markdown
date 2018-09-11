---
layout: post
author: tripledes
description: KubeVirt Memory Overcommitment
navbar_active: Blogs
pub-date: Sept 11
pub-year: 2018
category: news
comments: true
---

# KubeVirt memory overcommitment                                                                                                                                                                                                                                                                                   
One of the latest additions to KubeVirt has been the memory overcommitment feature which allows the memory being assigned to a Virtual Machine Instance to be different than what it requests to Kubernetes.
                                                                                                                 

## What it does
                                
As you might know already, when a pod is created in Kubernetes, it can define requests for resources like CPU or memory, those requests are taken into account for deciding to what node the pod will be scheduled. Usually, on a node, there are already some resources reserve
d or requested, Kubernetes itself [reserved some resources for its processes](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/) and there might be monitoring pods or storage pods already requesting resources as well, all those are also accoun
ted for what is left to run pods.
Having the memory overcommitment feture included in KubeVirt allows the users to assign the VMI more or less memory than set into the requests, offering more flexibility, giving the user the option to overcommit (or undercommit) the node's memory if needed.
     
         
## How does it work?
                         
It's not too complex to get this working, all what is needed is to have KubeVirt version [REPLACE]X.Y.Z[REPLACE] installed, which includes the aforementioned feature, and use the following settings on the VMI definition:
               
* `domain.memory.guest`: Defines the amount memory assigned to the VMI process (by libvirt).
* `domain.resources.requests.memory`: Defines the memory requested to Kubernetes by the pod that will run the VMI.
* `domain.resources.overcommitGuestOverhead`: Boolean switch to enable the feature.
            
Once those are in place, Kubernetes will consider the requested memory for scheduling while libvirt will define the domain with the amount of memory defined in `domain.memory.guest`. For example, let's define a VMI which requests *24534983Ki* but wants to use *25761732Ki*
 instead.           
             
```yaml              
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance       
metadata:     
  name: testvm1      
  namespace: kubevirt
spec:             
  domain:        
    memory:                                                                
      guest: "25761732Ki"
    resources:   
      requests:      
        memory: "24534983Ki"
      overcommitGuestOverhead: true
    devices:              
      disks:                       
      - volumeName: myvolume            
        name: mydisk                                                                                                          
        disk:               
          bus: virtio           
      - name: cloudinitdisk   
        volumeName: cloudinitvolume
        cdrom:
          bus: virtio
  volumes:           
  - name: myvolume
    registryDisk:                                                                                                                                                                                                                                                                     image: <registry_address>/kubevirt/fedora-cloud-registry-disk-demo:latest                                                                                                                                                                                                
  - cloudInitNoCloud:                                                                                                                                                                                                                                                                 userData: |                                                                                                                                                                                                                                                              
        #cloud-config                                                                                                                                                                                                                                                          
        hostname: testvm1
        users:                                                                                                                                                                                                                                                                            - name: kubevirt                                                                                                                                                                                                                                                     
            gecos: KubeVirt Project
            sudo: ALL=(ALL) NOPASSWD:ALL 
            passwd: $6$JXbc3063IJir.e5h$ypMlYScNMlUtvQ8Il1ldZi/mat7wXTiRioGx6TQmJjTVMandKqr.jJfe99.QckyfH/JJ.OdvLb5/OrCa8ftLr.
            shell: /bin/bash
            home: /home/kubevirt         
            lock_passwd: false
    name: cloudinitvolume
```

As explained already, the QEMU process spawn by libvirt, will get *25761732Ki* of RAM, minus some amount for the graphics and firmwares, the guest OS will see its total memory close to that amount, while Kubernetes would think the pod requests *24534983Ki*, making more ro
om to schedule more pods if needed.

Now let's imagine we want to undercommit, here's the same YAML definition but setting less memory than requested:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: testvm1
  namespace: kubevirt
spec:
  domain:
    memory:
      guest: "23308234Ki"
    resources:
      requests:
        memory: "24534983Ki"
      overcommitGuestOverhead: true
    devices:
      disks:
      - volumeName: myvolume
        name: mydisk
        disk:
          bus: virtio
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        cdrom:
          bus: virtio
  volumes:
  - name: myvolume
    registryDisk:
      image: <registry_url>/kubevirt/fedora-cloud-registry-disk-demo:latest
  - cloudInitNoCloud:
      userData: |
        #cloud-config
        hostname: testvm1
        users:
          - name: kubevirt
            gecos: KubeVirt Project
            sudo: ALL=(ALL) NOPASSWD:ALL
            passwd: $6$JXbc3063IJir.e5h$ypMlYScNMlUtvQ8Il1ldZi/mat7wXTiRioGx6TQmJjTVMandKqr.jJfe99.QckyfH/JJ.OdvLb5/OrCa8ftLr.
            shell: /bin/bash
            home: /home/kubevirt
            lock_passwd: false
    name: cloudinitvolume
```

## Why this is needed

At this point you might be asking yourself why would this feature be needed if Kubernetes already does resource management for you, right? Well, there might be few scenarios where this feature would be needed, for instance imagine you decide to have a cluster or few nodes
 completely dedicated to run Virtual Machines, this feature allows you to make use of all the memory in the nodes without really accounting for the already reserved or requested memory in the system.
Let's put it as an example, say a node has 100GiB of RAM, with 2GiB of reserved memory plus 1GiB requested by monitoring and storage pods, that leaves the user 97GiB of allocatable memory to schedule pods, so each VMI that needs to be started on a node needs to request an
 amount that would fit, if the user wants to run 10 VMIs on each node with 10GiB of RAM Kubernetes wouldn't allow that cause the sum of their requests would be more than what's allocatable in the node.
Using the memory overcommitment feature the user can tell Kubernetes that each VMI requests 9.7GiB and set `domain.memory.guest` to 10GiB.

The other way around, undercommitting the node, also works, for instance, to make sure that no matter how many VMIs will be under memory pressure the node will still be in good shape. Using the same node sizing, 100GiB, we could define 10 VMIs to request 9.7GiB, while giv
ing them exactly 9.0GiB, that'd leave around 7GiB for the node processes while Kubernetes wouldn't try to schedule any more pods on it cause all the requests already sum up to 100% of the allocatable memory.
