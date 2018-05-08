---
layout: post
author: fabiand
description: This is a weekly update from the KubeVirt team.
---
This is a weekly update from the KubeVirt team.

We are currently driven by

-   Building a solid user-story around KubeVirt

-   Caring about end-to-end (backend, core, ui)

-   Getting dependencies into shape (storage)

-   Improve the user-experience for users (UI, deployment)

-   Being easier to be used on Kubernetes and OpenShift

Within the last two weeks we achieved to:

-   Released KubeVirt v0.3.0
    <https://github.com/kubevirt/kubevirt/releases/tag/v0.3.0>

-   Merged VirtualMachinePresets (@stu-gott)
    (<https://github.com/kubevirt/kubevirt/pull/652>)

-   Merged OfflineVirtualMachine (@pkotas)
    (<https://github.com/kubevirt/kubevirt/pull/667>)

-   Merged ephemeral disk support (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/728>)

-   Fixes to test KubeVirt on OpenShift (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/774>)

-   Scheduler awareness of VM pods (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/673>)

-   Plain text inline cloud-init (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/757>)

-   Define guest specific labels to be used with presets (@yanirq)
    (<https://github.com/kubevirt/kubevirt/pull/767>)

-   Special note: A ton of automation, CI, and test fixes (@rmohr)

In addition to this, we are also working on:

-   Stable UUIDs for OfflineVirtualMachines (@fromanirh)
    (<https://github.com/kubevirt/kubevirt/pull/766>)

-   Subresources for consoles (@davidvossel)
    (<https://github.com/kubevirt/kubevirt/pull/770>)

-   Additional network glue approach (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/787>)

-   Improvement for testing on OpenShift (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/792>)

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/embed?src=<link xl:href=)"&gt;https://calendar.google.com/embed?src=<18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com>&lt;/link&gt;

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
