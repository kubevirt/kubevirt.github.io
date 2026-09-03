---
layout: post
author: Lee Yarwood
title: "Understanding KubeVirt's Host Kernel and Userspace Dependencies"
description: "Why virt-launcher's relationship with the host kernel matters, lessons from issue #16386, and how we sustainably manage this matrix across distributions."
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "kernel",
    "qemu",
    "libvirt",
    "live migration",
  ]
comments: true
pub-date: September 18
pub-year: 2026
---

KubeVirt runs each VM inside a `virt-launcher` pod. QEMU and libvirt are userspace processes scheduled like any other container, with host kernel devices (`/dev/kvm`, `/dev/vhost-net`, `/dev/net/tun`) mapped in. Like any workload that probes kernel device capabilities, a mismatch between the userspace stack and the host kernel can cause failures. What makes the virtualization case distinct is that those probe results feed directly into guest device feature negotiation and live-migration Application Binary Interface (ABI), so a kernel/userspace mismatch can surface not just as startup instability, but as broken live migrations across `virt-launcher` versions.

Upstream KubeVirt builds default `virt-launcher` images with Enterprise Linux (EL) userspace and runs CI against EL host kernels. When this EL userspace runs on non-EL host kernels, subtle compatibility assumptions can break in ways upstream CI never sees. A recent issue, [kubevirt/kubevirt#16386](https://github.com/kubevirt/kubevirt/issues/16386), brought this reality into sharp focus.

---

## The Anatomy of a Regression: Issue #16386

During upgrades from KubeVirt v1.6 to v1.7+ on Ubuntu worker nodes, live migrations failed across thousands of running VMs:

```text
qemu-kvm: Features 0x1c0010130afffaf unsupported. Allowed features: 0x10179bfffef
qemu-kvm: Failed to load virtio-net:virtio
qemu-kvm: error while loading state for instance 0x0 of device 'virtio-net'
qemu-kvm: load of migration failed: Operation not permitted
```

The bit difference `0x1c0000000000000` corresponds to three `virtio-net` feature bits for **UDP Segmentation Offload (USO)**:

* **Bit 54**: `VIRTIO_NET_F_GUEST_USO4`
* **Bit 55**: `VIRTIO_NET_F_GUEST_USO6`
* **Bit 56**: `VIRTIO_NET_F_HOST_USO`

### How the Layers Diverged

1. **Host Kernel Support:** Upstream Linux merged TAP USO (`TUN_F_USO4`/`USO6`) in **Linux 6.2**.
2. **QEMU Probe:** At VM startup, QEMU probes the host TAP backend via `ioctl(fd, TUNSETOFFLOAD, ...)`.
   * On **kernels >= 6.2** (e.g. Ubuntu 22.04 HWE, 24.04, 26.04), the probe succeeds. QEMU advertised USO, and modern guests negotiated bits 54–56.
   * On **kernels < 6.2** (e.g. stock CentOS Stream 9 / RHEL 9 on kernel 5.14), the ioctl returns `-EINVAL`. QEMU silently disabled USO.
3. **The Downstream Change:** In `qemu-kvm-9.1.0-20.el9` (shipped in KubeVirt 1.7), patch `kvm-virtio-net-disable-USO-for-virt-rhel9.6.patch` ([RHEL-80313](https://issues.redhat.com/browse/RHEL-80313)) retroactively disabled USO on `pc-q35-rhel9.6.0` machine types to fix RHEL 10 → RHEL 9 migration.
4. **The Failure:** Existing VMs running on Ubuntu nodes held negotiated USO bits from KubeVirt 1.6. When migrating to the 1.7 `virt-launcher`, the new QEMU rejected the incoming state.

### Why CI Missed It

Upstream KubeVirt release images are built on **CentOS Stream 9**, and upstream CI runs on **EL9 host kernels (5.14)**.

Because CI nodes run kernel 5.14, QEMU's TAP probe always failed. **USO was never enabled in CI**, so migration tests passed cleanly when the downstream QEMU patch dropped the feature. Only clusters running modern non-EL host kernels encountered the breakage.

---

## The Three-Way Dependency

`virt-launcher` is a translation layer between the host node and the guest OS:

```text
┌────────────────────────────────────────────────────────┐
│                      Guest OS                          │
│        (Kernel virtio drivers & negotiated ABI)        │
└───────────────────────────▲────────────────────────────┘
                            │ Virtio Features
┌───────────────────────────▼────────────────────────────┐
│              virt-launcher Pod (Container)             │
│       Bundled Userspace: QEMU, libvirt, swtpm...       │
│        (Upstream built on CentOS Stream 9/10)          │
└───────────────────────────▲────────────────────────────┘
                            │ ioctls (/dev/kvm, TAP, vhost)
┌───────────────────────────▼────────────────────────────┐
│                    Host Node Kernel                    │
│   (CentOS Stream, RHEL, Ubuntu, Debian, Flatcar...)   │
└────────────────────────────────────────────────────────┘
```

Compatibility requires alignment across all three boundaries:

* **Host Kernel ↔ Userspace:** Does the host kernel support the ioctl flags QEMU/libvirt probe for?
* **Userspace ↔ Target Userspace:** Does a newer QEMU in an updated `virt-launcher` accept the device state and feature bitmap of the source QEMU?
* **Userspace ↔ Guest OS:** Are virtual hardware features stable across migrations without breaking guest ABI?

---

## Aligned Stack Approaches Across Distributions

Distributions address this by aligning the entire stack, ensuring the host kernel and the containerized virtualization userspace are built from the same distribution base.

**Harvester** (built on SUSE / Rancher) does not run upstream CentOS Stream images on its nodes. Instead:

* **Host OS:** Runs on an immutable appliance OS derived from **SLE Micro**.
* **Userspace:** SUSE builds and ships its own `virt-launcher` images in `registry.suse.com` using **SLES / SLE Micro** packages from OBS.

**OpenShift Virtualization** (Red Hat) takes a similar approach within the OpenShift platform:

* **Host OS:** OpenShift enforces **Red Hat CoreOS (RHCOS)** as the worker node OS, built from the same RHEL base as the container images.
* **Userspace:** Red Hat builds and ships `virt-launcher` images from RHEL packages, validated against the same RHEL kernel version running on RHCOS worker nodes.

In both cases, because the host kernel and the containerized hypervisor share the same distribution base, they avoid the impedance mismatch that arises from running userspace built for one kernel generation on a host running a different one.

---

## Improving Transparency: Current Initiatives

We are working to make these boundaries explicit:

* **User Guide Requirements ([#1029](https://github.com/kubevirt/user-guide/pull/1029)):** Documented host kernel and virtualization userspace requirements for cluster operators (now merged).
* **Architectural Gap Tracking ([kubevirt#19000](https://github.com/kubevirt/kubevirt/issues/19000)):** Auditing implicit dependencies between `virt-launcher`, `virt-handler`, and host kernel capabilities.
* **Automated Support Matrix ([sig-release#69](https://github.com/kubevirt/sig-release/issues/69)):** Automatically publishing a release → userspace/kernel matrix by extracting pinned component NEVRAs (**N**ame, **E**poch, **V**ersion, **R**elease, **A**rchitecture) from `hack/rpm-deps.sh`.

---

## Moving Forward: Shared Community Ownership

Documenting assumptions is essential, but documentation alone does not prevent regressions.

Upstream maintainers validate release artifacts built on Enterprise Linux userspace and tested on EL host kernels. Upstream cannot realistically absorb the testing matrix and debugging burden of arbitrary host distributions without dedicated capacity.

If you rely on KubeVirt on non-EL hosts (Ubuntu, Debian, Flatcar, Talos, etc.):

1. **Third-Party CI:** Provide external CI lanes that test these host distributions against KubeVirt pull requests and releases.
2. **Aligned Virt Stacks:** Help maintain or validate alternative `virt-launcher` bases where host/userspace alignment is required.

---

## Get Involved

* Share your thoughts on the [kubevirt-dev mailing list](https://groups.google.com/g/kubevirt-dev).
* Contribute to documentation in [kubevirt/user-guide#1029](https://github.com/kubevirt/user-guide/pull/1029).
* Join the weekly [community meetings](https://github.com/kubevirt/community#community-meetings) to discuss multi-distro CI and testing.
