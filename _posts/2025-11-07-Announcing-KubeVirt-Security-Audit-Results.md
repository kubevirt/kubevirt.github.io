---
layout: post
author: KubeVirt Maintainers
title: Announcing the results of our Security Audit
description: As part of our application to Graduate, KubeVirt has a security audit performed by a third-party, organised through the CNCF and OSTIF.
navbar_active:
pub-date: November 07
pub-year: 2025
category: news
tags:
   [
     "KubeVirt",
     "graduation",
     "security",
     "community",
    "cncf",
     "milestone",
     "party time"
   ]

---

The KubeVirt Community is very pleased to share the results of our security audit, completed through the guidance of the Open Source Technology Improvement Fund (OSTIF) and the technical expertise of Quarkslab.

This is a critical step in KubeVirt moving to Graduation within the CNCF framework, and is the first time the project has been publicly audited.

The audit was conducted by Quarkslab earlier this year, beginning with an architectural review of KubeVirt and the creation of a threat model that identified threat actors, attack scenarios, and attack surfaces of the project. These were used to then test, prod, and poke to uncover and exploit any weak points. 

The audit found the following:

* 15 findings with a Security Impact:
    * 0 Critical
    * 1 High
        * [CVE-2025-64324](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-46xp-26xh-hpqh)
    * 7 Medium
        * [CVE-2025-64432](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-38jw-g2qx-4286)
        * [CVE-2025-64433](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-qw6q-3pgr-5cwq)
        * [CVE-2025-64434](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-ggp9-c99x-54gp)
        * [CVE-2025-64435](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-9m94-w2vq-hcf9)
        * [CVE-2025-64436](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-7xgm-5prm-v5gc)
        * [CVE-2025-64437](https://github.com/kubevirt/kubevirt/security/advisories/GHSA-2r4r-5x78-mvqf)
    * 4 Low
    * 3 Informational

Quarkslab also provided us with a Custom Threat Model and Fix Recommendations, and kept in touch after delivering the audit to help us understand and address the weaknesses they found. One of their team even volunteered their time to help remediate some of these issues, which we greatly appreciated!

These findings were provided to the project maintainers privately with an agreed response time to allow KubeVirt to address them prior to publication. 

The KubeVirt maintainers are very happy with these results, as they demonstrate not only the strength and security focus of our community, as well as the payoff of our earlier investment of moving to non-privileged by default, and by being compliant with the standard Kubernetes Security Model, which includes SELinux policies, seccomp and Pod Security Standards. It is worth noting that Kubernetes is also maturing and providing more security features, allowing KubeVirt and other projects in the ecosystem to inherently increase our security. 

This all highlights the unique benefits and additional isolation of running virtual machines as containers in addition to the benefits of using virtual machines.

Having your project audited is both nerve-inducing and extremely comforting. The KubeVirt project is deeply invested in following security best practices, and part of these best practices is having your project audited by a third party to find any possible weaknesses before a malicious actor. KubeVirt maintainers appreciate the OSTIF initiative in promoting security of CNCF projects.

You can read the [full Audit Report here](https://ostif.org/wp-content/uploads/2025/10/KubeVirt_OSTIF_Report_25-06-2150-REP_v1.2.pdf).

<!-- [Quarkslab's blog on the process here](XXX) -->

And [OSTIF's blog here](https://ostif.org/kubevirt-audit-complete/).

A huge thanks to everyone involved:

Quarkslab: Sébastien Rolland, Mihail Kirov, and Pauline Sauder<br>
OSTIF: Helen Woeste and Amir Montazery<br>
KubeVirt: Jed Lejosne, Ľuboslav Pivarč, Vladik Romanovsky, Federico Fossemò, Stu Gott, Roman Mohr, Fabian Deutsch, and Andrew Burden

We recommend users update their clusters to the latest supported z-stream version of KubeVirt. See our [KubeVirt to Kubernetes version support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information on supported KubeVirt versions.
