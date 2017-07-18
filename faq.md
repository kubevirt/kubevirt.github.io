# Frequently Asked Questions

## Can I perform a 1:1 translation of my libvirt domain xml to a VM Spec?

Probably not. libvirt is intended to be run on a host. And the domain xml is
based on this assumption, this implies that the domain xml allows you to access
host local resources i.e. local paths, host devices, and host device
configurations.
A VM Spec on the other hand is designed to work with cluster resources. And it
does not permit to address host resources.


## Does a VM Spec support all features of libvirt?

No. libvirt has a wide range of features, reaching beyond pure virtualization
fatures, into host, network, and storage management. The API was driven by the
requirements of running virtualization on a host.
A VM Spec however is a VM definition on the _cluster level_, this by itself
means that the specification has different requirements, i.e. it also needs to
include scheduling informations
And KubeVirt specifically builds on Kubernetes, which allows it to reuse the
subsystems for consuming network and storage, which on the other hand means
that the corresponding libvirt features will not be exposed.
Another


## Is KubeVirt a replacement for $MYVMMGMTSYSTEM?

Maybe. The primary goal of KubeVirt is to allow running virtual machines on
top of Kubernetes. It's focused on the virtualization bits.
General virtualization management systems like i.e. OpenStack or oVirt usually
consist of some additional services which take care of i.e. network management,
host provisioning, data warehousing, just to name a few. These services are out
of scope of KubeVirt.
That being said, KubeVirt is intended to be part of a virtualization management
system. It can be seen as an VM cluster runtime, and additional components
provide additional functionality to provide a nice coherent user-experience.


## Is KubeVirt like ClearContainers?

No. [ClearContainers](https://github.com/clearcontainers/runtime)
are about using VMs to isolate pods or containers on the container runtime
level.
KubeVirt on the other hand is about allowing to manage virtual machines on a
cluster level.

But beyond that it's also how virtual machines are exposed.
ClearContainers hide the fact that a virtual machine is used, but KubeVirt is
highly interested in providing an API to configure a virtual machine.


## Is KubeVirt like virtlet?

Somewhat. [virtlet](https://github.com/Mirantis/virtlet) is a CRI
implemetation to run virtual machines instead of containers.

The key differences to KubeVirt are:

- **It's a CRI.** This implies that the VM runtime is on the host, and that the
  kubelet is configured to use it.
  KubeVirt on the other hand can be deplyed as a native Kubernetes add-on.
- **Pod API.**  The virtlet is using a Pod API to specify the VM. Certain
  fields like i.e. volumes are mapped to the corresponding VM functionality.
  This is problematic, there are many details to VMs which can not be mapped
  to a Pod counterpart. Eventually annotations can be used to cover those
  properties.
  KubeVirt on the other hand exposes a VM specific API, which tries to cover
  all properties of a VM.


## Why Kubernetes and not bringing containers to OpenStack or oVirt ?

We think that Container workloads are the future. Therefore we want to add VM
support on top of a container management system instead of building container
support into a  VM management system.

