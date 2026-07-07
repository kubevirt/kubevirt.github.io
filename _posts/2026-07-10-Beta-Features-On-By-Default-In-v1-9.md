---
layout: post
author: iholder101
title: "Beta Features Enabled by Default in KubeVirt v1.9"
description: Starting from v1.9, all Beta feature gates are enabled by default. Learn what this means for your cluster and how to control feature gate behavior.
navbar_active: Blogs
pub-date: July 10
pub-year: 2026
category: news
tags:
  [
    "KubeVirt",
    "v1.9",
    "feature gates",
    "beta",
    "upgrade",
    "VEP"
  ]
comments: true
---

Starting from KubeVirt v1.9, **all Beta feature gates are enabled by default**.
This is a significant behavioral change from previous versions, where Beta
features had to be explicitly opted into.
If you are a downstream vendor, cluster administrator, or anyone deploying
KubeVirt in production, please read on to understand what this means and how
to prepare.

## Why This Change?

The Beta phase of a feature is a "dress rehearsal" before General
Availability (GA).
During this phase, the community needs to ensure the feature is stable,
gather wide user feedback, and validate that the API remains solid.

Previously, Beta features were off by default. This meant they were often
under-tested in real environments, limiting the community's ability to catch
issues early. By enabling Beta features by default, we:

- **Test Beta features in CI with every PR**, catching regressions early.
- **Turn every contributor into a Beta tester by default** during
  development.
- **Test Beta features alongside each other**, uncovering interaction bugs.
- **Give reviewers higher confidence when approving GA graduation**, backed
  by real-world exposure rather than opt-in-only testing.

This change was proposed and discussed publicly in
[VEP 229](https://github.com/kubevirt/enhancements/blob/main/veps/meta-VEPs/229-beta-features-on-by-default/vep.md)
and implemented in
[PR #17405](https://github.com/kubevirt/kubevirt/pull/17405).

## What Changes in Practice?

### Before v1.9

All Beta feature gates were **disabled** by default.
To use a Beta feature, you had to explicitly add it to
`spec.configuration.developerConfiguration.featureGates` in the KubeVirt CR:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - Snapshot
        - ImageVolume
```

### From v1.9 Onwards

All Beta feature gates are **enabled** by default.
To disable a Beta feature you do not want, add it to
`spec.configuration.developerConfiguration.disabledFeatureGates`:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      disabledFeatureGates:
        - Snapshot
        - ImageVolume
```

Note that Alpha features remain off by default and must still be explicitly
enabled via `featureGates`.

## Feature Gate Report - Know What Is Active

To help downstream vendors and cluster administrators understand which
features are active and at what maturity level, starting from v1.9,
KubeVirt ships a **feature gate report** as part of every release's
artifacts.

This is a JSON file listing every non-GA feature gate and its current
state (Alpha, Beta, or Deprecated). You can find it in the
[release artifacts](https://github.com/kubevirt/kubevirt/releases)
for each version.

You can also generate the report yourself from any KubeVirt source
tree by running:

```bash
make feature-gate-report
```

At the time of writing, the feature gate report looks as follows
(the actual report shipped with the v1.9 release artifacts may
differ):

```json
[
  {"name": "AlignCPUs", "state": "Alpha"},
  {"name": "CPUManager", "state": "Alpha"},
  {"name": "ConfigurableHypervisor", "state": "Alpha"},
  {"name": "ContainerPathVolumes", "state": "Alpha"},
  {"name": "DecentralizedLiveMigration", "state": "Alpha"},
  {"name": "DeclarativeHotplugVolumes", "state": "Alpha"},
  {"name": "DownwardMetrics", "state": "Alpha"},
  {"name": "EnableVirtioFsStorageVolumes", "state": "Alpha"},
  {"name": "ExperimentalIgnitionSupport", "state": "Alpha"},
  {"name": "GPUsWithDRA", "state": "Alpha"},
  {"name": "HostDevices", "state": "Alpha"},
  {"name": "HostDevicesWithDRA", "state": "Alpha"},
  {"name": "HostDisk", "state": "Alpha"},
  {"name": "HotplugVolumes", "state": "Alpha"},
  {"name": "HypervStrictCheck", "state": "Alpha"},
  {"name": "IncrementalBackup", "state": "Alpha"},
  {"name": "LibvirtHooksServerAndClient", "state": "Alpha"},
  {"name": "OptOutRoleAggregation", "state": "Alpha"},
  {"name": "PCINUMAAwareTopology", "state": "Alpha"},
  {"name": "PersistentReservation", "state": "Alpha"},
  {"name": "RebootPolicy", "state": "Alpha"},
  {"name": "ReservedOverheadMemlock", "state": "Alpha"},
  {"name": "Root", "state": "Alpha"},
  {"name": "Sidecar", "state": "Alpha"},
  {"name": "Template", "state": "Alpha"},
  {"name": "UtilityVolumes", "state": "Alpha"},
  {"name": "VGPULiveMigration", "state": "Alpha"},
  {"name": "VSOCK", "state": "Alpha"},
  {"name": "VmiMemoryOverheadReport", "state": "Alpha"},
  {"name": "WorkloadEncryptionSEV", "state": "Alpha"},
  {"name": "WorkloadEncryptionTDX", "state": "Alpha"},
  {"name": "ExternalNetResourceInjection", "state": "Beta"},
  {"name": "ImageVolume", "state": "Beta"},
  {"name": "KubevirtSeccompProfile", "state": "Beta"},
  {"name": "LiveUpdateNADRef", "state": "Beta"},
  {"name": "MigrationPriorityQueue", "state": "Beta"},
  {"name": "NodeRestriction", "state": "Beta"},
  {"name": "PasstBinding", "state": "Beta"},
  {"name": "PodSecondaryInterfaceNamingUpgrade", "state": "Beta"},
  {"name": "SecureExecution", "state": "Beta"},
  {"name": "Snapshot", "state": "Beta"},
  {"name": "VideoConfig", "state": "Beta"},
  {"name": "DisableMDEVConfiguration", "state": "Deprecated"},
  {"name": "DockerSELinuxMCSWorkaround", "state": "Deprecated"},
  {"name": "MultiArchitecture", "state": "Deprecated"}
]
```

Using this report, you can easily identify all Beta features that will now
be on by default and decide which, if any, you want to disable.

## Upgrade Considerations

### Upgrading from v1.8 to v1.9

If you are upgrading from v1.8, the `disabledFeatureGates` mechanism is
already available to you.
Before upgrading, review the feature gate report and add any Beta features
you want to keep disabled to `disabledFeatureGates` in your KubeVirt CR.

### Upgrading from v1.7 (or older) to v1.9

The `disabledFeatureGates` field was introduced in
[v1.8](https://github.com/kubevirt/enhancements/issues/104).
If you are skipping v1.8 and upgrading directly from v1.7 to v1.9, be
aware that:

- After the upgrade, all Beta features will become active immediately.
- You should update your KubeVirt CR to add `disabledFeatureGates` as soon
  as the upgrade completes.
- We recommend testing the upgrade in a staging environment first, with
  particular attention to the newly enabled Beta features.

### General Recommendations

1. **Automatically disable Beta feature gates in production.** Use the
   feature gate report JSON from the release artifacts to programmatically
   populate the `disabledFeatureGates` list in your KubeVirt CR. This
   ensures newly promoted Beta features are not silently enabled in
   production after an upgrade.
2. **Do not skip v1.8.** The `disabledFeatureGates` mechanism was
   introduced in v1.8. If you upgrade directly from v1.7 (or older)
   to v1.9, Beta features will be unconditionally enabled until you
   manually patch the KubeVirt CR post-upgrade. Upgrading to v1.8
   first lets you configure `disabledFeatureGates` before Beta
   features become on by default.

## Downstream Vendors

If you ship a product based on KubeVirt, this change directly affects your
release pipeline. Here are specific recommendations:

### Non-HCO Deployments

Use `disabledFeatureGates` in your KubeVirt CR to disable features that are
not ready for your product:

```yaml
spec:
  configuration:
    developerConfiguration:
      disabledFeatureGates:
        - FeatureYouWantDisabled
```

As recommended above, use the feature gate report JSON from the release
artifacts to programmatically extract all Beta features and disable them
in your KubeVirt CR.

### HCO-Based Deployments

[HCO](https://github.com/kubevirt/hyperconverged-cluster-operator)
(Hyperconverged Cluster Operator) will explicitly manage which Beta
features are enabled or disabled.
HCO maintainers will use the feature gate report to decide on defaults,
with an in-code exception list for features they choose to configure
differently.

If HCO's defaults do not match your needs, you can override the KubeVirt
CR's `disabledFeatureGates` list using
[JSON patches](https://github.com/kubevirt/hyperconverged-cluster-operator/blob/main/docs/cluster-configuration.md).

## Summary

| Aspect | Before v1.9 | From v1.9 |
|---|---|---|
| Alpha features | Off by default | Off by default (no change) |
| Beta features | Off by default | **On by default** |
| GA features | Always on | Always on (no change) |
| Opt-in mechanism | `featureGates` | `featureGates` (Alpha only) |
| Opt-out mechanism | `disabledFeatureGates` (from v1.8) | `disabledFeatureGates` (from v1.8) |
| Feature visibility | Parse source code | **JSON report in release artifacts** |

This change helps the community deliver more stable features at GA.
If you have questions, please reach out on the
[kubevirt-dev mailing list](https://groups.google.com/g/kubevirt-dev)
or join the `#kubevirt-dev` channel on
[Kubernetes Slack](https://kubernetes.slack.com/archives/C0163DT0R8X).

For full details, see
[VEP 229](https://github.com/kubevirt/enhancements/blob/main/veps/meta-VEPs/229-beta-features-on-by-default/vep.md).
