---
layout: labs
title: Easy installation on Cloud Providers
permalink: pages/cloud
lab: kubernetes
tags: [GCP, AWS, AliCloud, azure, Amazon, Google, quickstart, tutorial]
order: 1
---

# Easy install using Cloud Providers

## Introduction

> info ""
> KubeVirt has been tested on GCP and AWS providers, this approach is intended for demonstration purposes similar to the environments for [Kind]({% link pages/quickstart_kind.md %}) and [Minikube]({% link pages/quickstart_minikube.md %}) and of course the [Katacoda scenarios](https://katacoda.com/kubevirt).

KubeVirt can be tested on external Cloud Providers like AWS, Azure, GCP, AliCloud, and others.

> warning ""
> Note this setup **is not meant for production**, it is meant to give you a quick taste of KubeVirt's functionality.

## Step1: Create a new K8S cluster

> error ""
> Usage of Cloud Providers like GCP or AWS (or others) might have additional costs or require trial account and setup prior to be able to run those instructions, like for example, creating a default keypair or others.

Check Kubernetes.io guide for each cloud provider to match your use case:

| Provider | Link                                                                             |
| -------- | -------------------------------------------------------------------------------- |
| Others   | <https://kubernetes.io/docs/setup/production-environment/turnkey/>               |
| AliCloud | <https://kubernetes.io/docs/setup/production-environment/turnkey/alibaba-cloud/> |
| AWS      | <https://kubernetes.io/docs/setup/production-environment/turnkey/aws/>           |
| Azure    | <https://kubernetes.io/docs/setup/production-environment/turnkey/azure/>         |
| GCP      | <https://kubernetes.io/docs/setup/production-environment/turnkey/gce/>           |

> info ""
> Create a disk of 30Gb at least.

After following the instructions provided by [Kubernetes.io](https://kubernetes.io), `kubectl` can be used to manage the cluster.

### Deploy KubeVirt Operator

Having the cluster up and running, let's set the _version_ environment
variable that will be used on few commands:

```bash
{% include scriptlets/quickstart_cloud/04_setenv_version.sh -%}
```

Now, using the `kubectl` tool, let's deploy the KubeVirt Operator:

```bash
{% include scriptlets/quickstart_cloud/05_deploy_operator.sh -%}
```

Check it's running:

```bash
{% include scriptlets/quickstart_cloud/06_check_operator_running.sh -%}

NAME                             READY     STATUS              RESTARTS   AGE
virt-operator-6c5db798d4-9qg56   0/1       ContainerCreating   0          12s
...
virt-operator-6c5db798d4-9qg56   1/1       Running   0         28s
```

We'll need to execute the command above few times (or add _-w_ for _watching_
the pods), until the operator is _Running_ and _Ready_ (1/1), then it's time
to head to the next section.

### Check for the Virtualization Extensions

To check if your VM's CPU supports virtualization extensions execute the
following command:

```bash
{% include scriptlets/quickstart_cloud/07_verify_virtualization.sh -%}
```

If the command doesn't generate any output, create the following _ConfigMap_
so that KubeVirt uses emulation mode, otherwise skip to the next section:

```bash
{% include scriptlets/quickstart_cloud/08_emulate_vm_extensions.sh -%}
```

### Deploy KubeVirt

KubeVirt is then deployed by creating a dedicated custom resource:

```bash
{% include scriptlets/quickstart_cloud/09_deploy_kubevirt.sh -%}
```

Check the deployment:

```bash
{% include scriptlets/quickstart_cloud/06_check_operator_running.sh -%}

NAME                               READY     STATUS    RESTARTS   AGE
virt-api-649859444c-fmrb7          1/1       Running   0          2m12s
virt-api-649859444c-qrtb6          1/1       Running   0          2m12s
virt-controller-7f49b8f77c-kpfxw   1/1       Running   0          2m12s
virt-controller-7f49b8f77c-m2h7d   1/1       Running   0          2m12s
virt-handler-t4fgb                 1/1       Running   0          2m12s
virt-operator-6c5db798d4-9qg56     1/1       Running   0          6m41s
```

Once we applied the _Custom Resource_ the operator took care of deploying the
actual KubeVirt pods (_virt-api_, _virt-controller_ and _virt-handler_). Again
we'll need to execute the command until everything is _up&running_
(or use _-w_).

### Install virtctl

An additional binary is provided to get quick access to the serial and graphical ports of a VM, and handle start/stop operations.
The tool is called _virtctl_ and can be retrieved from the release page of KubeVirt:

```bash
{% include scriptlets/quickstart_cloud/11_get_virtctl.sh -%}
```

If [`krew` plugin manager](https://krew.dev/) is [installed](https://github.com/kubernetes-sigs/krew/#installation), `virtctl` can be installed via `krew`:

```bash
$ kubectl krew install virt
```

Then `virtctl` can be used as a kubectl plugin. For a list of available commands run:

```bash
$ kubectl virt help
```

Once krew plugin is installed, every occurrence throughout this guide of

```bash
$ ./virtctl <command>...
```

should then be read as

```bash
$ kubectl virt <command>...
```

{% include labs-description.md %}
