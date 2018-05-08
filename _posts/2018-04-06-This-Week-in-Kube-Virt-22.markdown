---
layout: post
author: fabiand
description: This is a close-to weekly update from the KubeVirt team.
---
This is a close-to weekly update from the KubeVirt team.

In general there is now more work happening outside of the core kubevirt
repository.

We are currently driven by

-   Building a solid user-story around KubeVirt

-   Caring about end-to-end (backend, core, ui)

-   Getting dependencies into shape (storage)

-   Improve the user-experience for users (UI, deployment)

-   Being easier to be used on Kubernetes and OpenShift

Within the last two weeks we achieved to:

-   Release KubeVirt v0.4.0
    (<https://github.com/kubevirt/kubevirt/releases/tag/v0.4.0>)

-   Many networking fixes (@mlsorensen @vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/870>
    <https://github.com/kubevirt/kubevirt/pull/869>
    <https://github.com/kubevirt/kubevirt/pull/847>
    <https://github.com/kubevirt/kubevirt/pull/856>
    <https://github.com/kubevirt/kubevirt/pull/839>
    <https://github.com/kubevirt/kubevirt/pull/830>)

-   Aligned config reading for virtctl (@rmohr)
    (<https://github.com/kubevirt/kubevirt/pull/860>)

-   Subresource Aggregated API server for console endpoints (@vossel)
    (<https://github.com/kubevirt/kubevirt/pull/770>)

-   Enable OpenShift tests in CI (@alukiano @rmohr)
    (<https://github.com/kubevirt/kubevirt/pull/833>)

-   virtctl convenience functions for start/stop of VMs (@sgott)
    (<https://github.com/kubevirt/kubevirt/pull/817>)

-   Ansible - Improved Gluster support for kubevirt-ansible
    (<https://github.com/kubevirt/kubevirt-ansible/pull/174>)

-   POC Device Plugins for KVM and network (@mpolednik @phoracek)
    <https://github.com/kubevirt/kubernetes-device-plugins>

In addition to this, we are also working on:

-   Additional network glue approach (@vladikr)
    (<https://github.com/kubevirt/kubevirt/pull/787>)

-   CRD validation using OpenAPIv3 (@vossel)
    (<https://github.com/kubevirt/kubevirt/pull/850>)

-   Windows VM tests (@alukiano)
    (<https://github.com/kubevirt/kubevirt/pull/809>)

-   Data importer - Functional tests
    (<https://github.com/kubevirt/containerized-data-importer/pull/81>)

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/embed?src=<link xl:href=)"&gt;https://calendar.google.com/embed?src=<18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com>&lt;/link&gt;

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
