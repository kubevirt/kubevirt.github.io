---
title: Get started with KubeVirt
layout: default
---

## Quick all-in-one demo inside KVM

First time users of KubeVirt are encouraged to make use of the quick demo which
provides an all-in-one Kubernetes & KubeVirt installation in a KVM compatible
disk image.

### Running automatically

The manual steps listed in the next section can be performed automatically
by running:

```shell
 $ curl http://run.kubevirt.io/demo.sh | bash
```

If you wish to audit it first, the source for this script is [kept in
GIT](https://github.com/kubevirt/run), alternatively follow the manual
steps instead.

### Running manually

The KubeVirt quick demo requires a couple of tools to be present to build
and run the disk images

* make
* qemu-system-x86_64 or qemu-kvm
* virt-builder

These can be installed as follows:

```shell
 $ dnf install qemu-system-x86_64 make virt-builder  (Fedora)
 $ yum install qemu-kvm make virt-builder (RHEL / CentOS)
```

Once the prerequisites are installed, the demo disk image can be created and run
using

```shell
 $ git clone https://github.com/kubevirt/demo.git
 $ cd demo
 $ make build
 $ ./run-demo.sh
```
