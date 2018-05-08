---
layout: post
author: fabiand
description: This is a bi-weekly update from the KubeVirt team.
---
This is a bi-weekly update from the KubeVirt team.

We are currently driven by

-   Building a solid user-story around KubeVirt

-   Caring about end-to-end (backend, core, ui)

-   Getting dependencies into shape (storage)

-   Improve the user-experience for users (UI, deployment)

-   Being easier to be used on Kubernetes and OpenShift

Within the last two weeks we achieved to:

-   Support for native file-system PVs as disk storage (@alukiano,
    @davidvossel) (<https://github.com/kubevirt/kubevirt/pull/734>,
    <https://github.com/kubevirt/kubevirt/pull/671>)

-   Support for native pod networking for VMs (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/686>)

-   Many patches to improve kubevirt-ansible usability
    (<https://github.com/kubevirt/kubevirt-ansible/pulse/monthly>)

-   Introduce the kubernetes-device-plugins (@mpolednik)
    (<https://github.com/kubevirt/kubernetes-device-plugins/>)

-   Introduce the kubernetes-device-plugin for bridge networking
    (@mpolednik)
    (<https://github.com/kubevirt/kubernetes-device-plugins/pull/4>)

-   Add vendor/ tree (@davidvossel)
    (<https://github.com/kubevirt/kubevirt/pull/715>)

-   Expose disk bus (@fromani)
    (<https://github.com/kubevirt/kubevirt/pull/672>)

-   Allow deploying OpenShift in vagrant (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/631>)

-   Release of v0.3.0-alpha.3
    (<https://github.com/kubevirt/kubevirt/releases/tag/v0.3.0-alpha.3>)

In addition to this, we are also working on:

-   Implement VirtualMachinePresets (@stu-gott)
    (<https://github.com/kubevirt/kubevirt/pull/652>)

-   Implement OfflineVirtualMachines (@pkotas)
    (<https://github.com/kubevirt/kubevirt/pull/667>)

-   Expose CPU requirements in VM pod (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/673>)

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/embed?src=<link xl:href=)"&gt;https://calendar.google.com/embed?src=<18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com>&lt;/link&gt;

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
