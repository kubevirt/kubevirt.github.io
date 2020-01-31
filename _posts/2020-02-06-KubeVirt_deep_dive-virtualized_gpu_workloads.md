---
layout: post
author: Pedro Ibáñez Requena
description: "KubeVirt Deep Dive: Virtualized GPU Workloads on KubeVirt - David Vossel, Red Hat & Vishesh Tanksale, NVIDIA"
navbar_active: Blogs
category: news
comments: true
title: NA KubeCon 2019 - KubeVirt Deep Dive: Virtualized GPU Workloads on KubeVirt - David Vossel, Red Hat & Vishesh Tanksale, NVIDIA
pub-date: February, 06
pub-year: 2019
---


In this video, David and Vishesh explore the architecture behind KubeVirt and how NVIDIA is leveraging that architecture to power GPU workloads on Kubernetes. 
Using NVIDIA’s GPU workloads as a case of study, they provide a focused view on how host device passthrough is accomplished with KubeVirt as well as providing some 
performance metrics comparing KubeVirt to standalone KVM. 

## KubeVirt Intro
David introduces the talk showing what KubeVirt is and what is not:
- KubeVirt is not involved with managing AWS or GCP instances
- KubeVirt is not a competitor to Firecracker or Kata containers
- KubeVirt is not a container runtime replacement

He likes to define KubeVirt as:
> KubeVirt is a Kubernetes extension that allows running traditional VM workloads natively side by side with Container workloads.

But why KubeVirt?
- Already have on-premise solutions like OpenStack, oVirt
- And then there's the public cloud, AWS, GCP, Azure
- Why are we doing this VM management stuff yet again?

The answer is that the initial motivation for it was this idea of infrastructure convergence:
![kubevirt_infrastructure_convergence](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/kubevirt_infrastructure_convergence.png "KubeVirt infrastructure convergence")

The transition to the cloud model involves multiple stacks, containers and virtual machines, old code and new code. 
With KubeVirt all this is simplified with just one stack to manage containers and virtual machines to run old code and new code.
![kubevirt_one_stack](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/kubevirt_one_stack.png "KubeVirt one stack")


The workflow convergence means that:
- Converging VM management into container management workflows
- Using the same tooling (kubectl) for containers and Virtual Machines (VM)
- Keeping the declarative API for VM management (just like pods, deployments, etc...)

An example of a VM Instance in YAML could be so simple as the following example:
```yaml
$ cat <<EOF | kubectl create -f -
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachineInstance
...
	spec:
		domain:
			cpu: 
				cores: 2
			devices:
				disk: fedora29
```
## Architecture

The truth here is that a KubeVirt VM is a KVM+qemu process running inside a pod. Simple like that.
![kubevirt_virtual_machine](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/kubevirt_virtual_machine.png "KubeVirt VM = KVM+qemu")


The VM Launch flow is shown in the following diagram. Since the user posts a VM manifest to the cluster until the Kubelet spins up the VM pod.
And finaly the virt-handler instructs the virt-launcher how to launch the qemu.
![kubevirt_vm_launch_flow](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/kubevirt_vm_launch_flow.png "KubeVirt VM launch flow")


The storage in KubeVirt is used in the same way as the pods, if there is a need to have persistent storage in a VM a PVC (Persistent Volume Claim) 
needs to be created. 
![kubevirt_volumes](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/kubevirt_volumes.png "KubeVirt volumes")

For example, if you have a VM in your laptop, you can upload that image using the containerized-data-importer (CDI) to a PVC and then you can attach
that PVC to the VM pod to get it running.

About the use of network services, the traffic routes to the KubeVirt VM in the same way it does to container workloads. Also with Multus there is
the possibility to have different network interfaces per VM.

For using the Host Resources:
- VM Guest CPU and NUMA Affinity
		- CPU Manager (pining)
		- Topology Manager (NUMA nodes)
- VM Guest CPU/MEM requirements
		- POD resource request/limits
- VM Guest use of Host Devices
		- Device Plugins for access to (/dev/kvm, SR-IOV, GPU passthrough)
		- POD resource request/limits for device allocation

## GPU/vGPU in Kubevirt VMs

After the introduction of David, Vishesh takes over and talks in-depth the whys and hows of GPUs in Virtual Machines. Lots of new Machine and Deep learning applications
are taking advance of the GPU workloads. Nowadays the Big data is one of the main consumers of GPUs but there are some gaps, the gaming and professional graphics sector 
still need to run VMs and have native GPU functionalities, that is why NVIDIA decided to work with KubeVirt.
![gpus_on_kubevirt](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/gpus_on_kubevirt.png "GPU/vGPU on KubeVirt")

To enable the device pass-through NVIDIA has developed the KubeVirt GPU device Plugin, it is available in GitHub: https://github.com/NVIDIA/kubevirt-gpu-device-plugin
It's opensource and anybody can take a look to it and download it.

Using the device plugin framework is a natural choice to provide GPU access to Kubevirt VMs, 
the following diagram shows the different layers involved in the GPU pass-through architecture:
![kubevirt_gpu_passthrough](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/kubevirt_gpu_passthrough.png "KubeVirt GPU passthrough")

Vishesh also comments an example of a YAML code where it can be seen the Node Status containing the NVIDIA card information (5 GPUS in that node), the Virtual Machine specification
containing the `deviceName` that points to that NVIDIA card and also the Pod Status where the user can set the limits and request for that resource as 
any other else in Kubernetes.
![kubevirt_gpu_pass_yaml](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/gpu_pass_yaml.png "KubeVirt GPU passthrough yaml")

The main Device Plugin Functions are:
- GPU and vGPU device Discovery
	− GPUs with VFIO-PCI driver on the host are identified
	− vGPUs configured using Nvidia vGPU manager are identified
- GPU and vGPU device Advertising
	− Discovered devices are advertised to kubelet as allocatable resources
- GPU and vGPU device Allocation
	− Returns the PCI address of allocated GPU device
- GPU and vGPU Health Check
		− Performs health check on the discovered GPU and vGPU devices

To understand how the GPU passthrough lifecycle works Vishesh shows the different phases involve in the process using the following diagram:
![gpu_pass_lifecycle](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/gpu_pass_lifecycle.png "KubeVirt GPU passthrough lifecycle")

In the following diagram there are some of the Key features that NVIDIA is using with KubeVirt:
![NVIDIA_usecase_keyfeatures](/assets/2020-02-06-KubeVirt_deep_dive-virtualized_gpu_workloads/NVIDIA_usecase_keyfeatures.png "KubeVirt NVIDIA usecase keyfeatures")

If you are interested in the details of how the lifecycle works or in why NVIDIA is highly using some of the KubeVirt features listed above you may 
take a look to the video included in the following section.

## Video

<iframe width="560" height="315" style="height: 315px" src="https://www.youtube.com/embed/Qejlyny0G58" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Speakers

[David Vossel]() is currently a Principal Software Engineer at Red Hat ...

[Vishesh Tanksale]() is currently a Senior Software Engineer at NVIDIA. He is focussing on different aspects of enabling VM workload management on Kubernetes Cluster. 
He is specifically interested in GPU workloads on VMs. He is an active contributor to Kubevirt, a CNCF Sanbox Project.

## References
- [YouTube video: KubeVirt Deep Dive: Virtualized GPU Workloads on KubeVirt - David Vossel, Red Hat & Vishesh Tanksale, NVIDIA](https://www.youtube.com/watch?v=Qejlyny0G58)
- [Presentation: Virtualized GPU workloads on KubeVirt](https://static.sched.com/hosted_files/kccncna19/31/KubeCon%202019%20-%20Virtualized%20GPU%20Workloads%20on%20KubeVirt.pdf)
- [KubeCon NA 2019 event](https://kccncna19.sched.com/event/VnjX)
