---
layout: post
author: fabiand
description: This is a weekly update from the KubeVirt team.
---
This is a weekly update from the KubeVirt team.

In general there is now more work happening outside of the core kubevirt
repository.

We are currently driven by

-   Building a solid user-story around KubeVirt

-   Caring about end-to-end (backend, core, ui)

-   Getting dependencies into shape (storage)

-   Improve the user-experience for users (UI, deployment)

-   Being easier to be used on Kubernetes and OpenShift

Within the last two weeks we achieved to:

-   Multi platform (Windows, Mac, Linux) support for virtctl (@slintes)
    (<https://github.com/kubevirt/kubevirt/pull/811>)

-   Stable UUIDs for OfflineVirtualMachines (@fromanirh)
    (<https://github.com/kubevirt/kubevirt/pull/766>)

-   OpenShift support for CI (@alukiano, @rmohr)
    (<https://github.com/kubevirt/kubevirt/pull/792>)

-   v2v improvements - for easier imports of existing VMs (@pkliczewski)
    (<https://github.com/kubevirt/v2v-job>)

-   Data importer - to import existing disk images (@copejon @jeffvance)
    (<https://github.com/kubevirt/containerized-data-importer>)

-   POC Device Plugins for KVM and network (@mpolednik @phoracek)
    <https://github.com/kubevirt/kubernetes-device-plugins>

In addition to this, we are also working on:

-   Subresources for consoles (@davidvossel)
    (<https://github.com/kubevirt/kubevirt/pull/770>)

-   Additional network glue approach (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/787>)

-   virtctl convenience functions for start/stop of VMs (@sgott)
    (<https://github.com/kubevirt/kubevirt/pull/817>)

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/embed?src=<link xl:href=)"&gt;https://calendar.google.com/embed?src=<18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com>&lt;/link&gt;

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
