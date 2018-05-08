---
layout: post
author: fabiand
description: This is a close-to weekly update from the KubeVirt team.
---
This is a close-to weekly update from the KubeVirt team.

In general there is now more work happening outside of the core kubevirt
repository.

We are currently driven by

-   Closing a lot of loose ends

-   Stepping back to identify gaps for 1.0

Within the last two weeks we achieved to:

-   Release KubeVirt v0.4.1 to address some shutdown issues

    -   <https://github.com/kubevirt/kubevirt/releases/tag/v0.4.1>

-   Many VM life-cycle and guarantee fixes (@rmohr @vossel)

    -   <https://github.com/kubevirt/kubevirt/pull/951>

    -   <https://github.com/kubevirt/kubevirt/pull/948>

    -   <https://github.com/kubevirt/kubevirt/pull/935>

    -   <https://github.com/kubevirt/kubevirt/pull/838>

    -   <https://github.com/kubevirt/kubevirt/pull/907>

    -   <https://github.com/kubevirt/kubevirt/pull/883>

-   Pass labels from VM to pod for better Service integration (@rmohr)

    -   <https://github.com/kubevirt/kubevirt/pull/939>

-   Packaging preparations (@rmohr)

    -   <https://github.com/kubevirt/kubevirt/pull/941>

    -   <https://github.com/kubevirt/kubevirt/issues/924>

    -   <https://github.com/kubevirt/kubevirt/pull/950>

-   Controller readiness clarifications (@rmohr)

    -   <https://github.com/kubevirt/kubevirt/pull/901>

-   Validation improvements using CRD scheme and webhooks (@vossel)

    -   Webhook: <https://github.com/kubevirt/kubevirt/pull/911>

    -   Scheme: <https://github.com/kubevirt/kubevirt/pull/850>

    -   <https://github.com/kubevirt/kubevirt/pull/917>

-   Add Windows tests (@alukiano)

    -   <https://github.com/kubevirt/kubevirt/pull/809>

-   Improve PVC tests (@petrkotas)

    -   <https://github.com/kubevirt/kubevirt/pull/862>

-   Enable SELinux in OpenShift CI environment

-   Tests to run KubeVirt on Kubernetes 1.10

In addition to this, we are also working on:

-   virtctl expose convenience verb (@yuvalif)

    -   <https://github.com/kubevirt/kubevirt/pull/962>

-   CRIO support in CI

-   virtctl bash/zsh completion (@rmohr)

    -   <https://github.com/kubevirt/kubevirt/pull/916>

-   Improved error messages from virtctl (@fromanirh)

    -   <https://github.com/kubevirt/kubevirt/pull/934>

-   Improved validation feedback (@vossel)

    -   <https://github.com/kubevirt/kubevirt/pull/960>

Take a look at the pulse, to get an overview over all changes of this
week: <https://github.com/kubevirt/kubevirt/pulse>

Finally you can view our open issues at
<https://github.com/kubevirt/kubevirt/issues>

And keep track of events at our calendar
[18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com](https://calendar.google.com/embed?src=<link xl:href=)"&gt;https://calendar.google.com/embed?src=<18pc0jur01k8f2cccvn5j04j1g@group.calendar.google.com>&lt;/link&gt;

If you need some help or want to chat you can find us on
<irc://irc.freenode.net/#kubevirt>
