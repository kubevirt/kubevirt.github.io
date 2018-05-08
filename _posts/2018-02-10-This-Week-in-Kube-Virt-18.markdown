---
layout: post
author: fabiand
description: This is a weekly update from the KubeVirt team.
---
This is a weekly update from the KubeVirt team.

We are currently driven by

-   Building a solid user-story around KubeVirt

-   Caring about end-to-end (backend, core, ui)

-   Rework our architecture

-   Getting dependencies into shape (storage)

-   Improve the user-experience for users (UI, deployment)

-   Being easier to be used on Kubernetes and OpenShift

Within the last weeks we achieved to:

-   Move to a decentralized the architecture (@davidvossel)
    (<https://github.com/kubevirt/kubevirt/pull/663>)

-   Drop live migration for now (@davidvossel)
    (<https://github.com/kubevirt/kubevirt/pull/702>)

-   Change default network provider to flannel (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/710>)

-   Adjust uuid API (@mpolednik)
    (<https://github.com/kubevirt/kubevirt/pull/675>)

-   Make cirros and alpine ready for q35 (@rmohr)
    (<https://github.com/kubevirt/kubevirt/pull/688>)

In addition to this, we are also working on:

-   Decentralized pod networking (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/686>)

-   Implement VirtualMachinePresets (@stu-gott)
    (<https://github.com/kubevirt/kubevirt/pull/652>)

-   Implement OfflineVirtualMachines (@pkotas)
    (<https://github.com/kubevirt/kubevirt/pull/667>)

-   Allow deploying OpenShift in vagrant (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/631>)

-   Expose CPU requirements in VM pod (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/673>)

-   Add support for PVs via kubelet (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/671>)

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/embed?src=<link xl:href=)"&gt;https://calendar.google.com/embed?src=<18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com>&lt;/link&gt;

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
