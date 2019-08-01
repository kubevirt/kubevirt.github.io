---
layout: post
author: iranzo
description: KubeVirt is renaming Condition Types in next release
title: KubeVirt Condition Types Rename in Custom Resource
navbar_active: Blogs
pub-date: Aug 1
pub-year: 2019
category: news
---

## The announcement

Hi KubeVirt Community!

As per the message from Marc Sluiter on our [mailing list](https://groups.google.com/d/msg/kubevirt-dev/LhTm77nWxzM/Qr3c-hDWCQAJ):

~~~
Hello everybody,

today we merged a PR [0], which renamed the condition types on the KubeVirt custom resources.
This was done for alignment of conditions of all components in the KubeVirt ecosystem, which are deployed by the Hyperconverged Cluster Operator (HCO)[1], in order to make it easier for HCO to determine the deployment status of these components. The conditions are explained in detail in [2].

For KubeVirt this means that especially the "Ready" condition was renamed to "Available". This might affect you in case you used the "Ready" condition for waiting for a successful deployment of KubeVirt. If so, you need to update the corresponding command to something like `kubectl -n kubevirt wait kv kubevirt --for condition=Available`.
The second renamed condition is "Updating". This one is named "Progressing" now.
As explained in [2], there also is a new condition named "Degraded".
The "Created" and "Synchronized" conditions are unchanged.

These changes take effect immediately if you are deploying KubeVirt from the master branch, or starting with the upcoming v0.20.0 release.

[0] https://github.com/kubevirt/kubevirt/pull/2548
[1] https://github.com/kubevirt/hyperconverged-cluster-operator
[2] https://github.com/kubevirt/hyperconverged-cluster-operator/blob/master/docs/conditions.md

Best regards,
~~~

We're renaming some of the prior 'conditions' reported by the Custom Resources.

## What does it mean to us

We're making KubeVirt more compatible with the standard for Operators, when doing so, some of the `conditions` are changing, so check your scripts using checks for conditions to use the new ones.

|  **Prior**   |    **Actual**     | **Note**          |
| :----------: | :---------------: | :---------------- |
|  ~~Ready~~   |  **`Available`**  | **Updated**       |
| ~~Updating~~ | **`Progressing`** | **Updated**       |
|      -       |    `Degraded`     | **New condition** |
|   Created    |     `Created`     | **Unchanged**     |
| Synchronized |  `Synchronized`   | **Unchanged**     |

## References

Check for more information on the following URL's

- <https://github.com/kubevirt/kubevirt/pull/2548>
- <https://github.com/kubevirt/hyperconverged-cluster-operator>
- <https://github.com/kubevirt/hyperconverged-cluster-operator/blob/master/docs/conditions.md>
