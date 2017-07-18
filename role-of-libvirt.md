# The role of libvirt

[libvirt](https://libvirt.org) 

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
