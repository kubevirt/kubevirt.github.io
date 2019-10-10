---
layout: labs
title: KubeVirt Quickstart with Minikube
permalink: /quickstart_minikube/
redirect_from: "/get_kubevirt/"
order: 2
lab: kubernetes
---

# Easy install using minikube

In Step 1, we guide you through setting up your environment to launch Kubernetes via minikube

After it's ready, dive into the two labs below to help you get
acquainted with KubeVirt.

## Step 1: Prepare minikube environment

This guide will help you deploying [KubeVirt](https://kubevirt.io) on
Kubernetes, we'll be using
[Minikube](https://github.com/kubernetes/minikube/){:target="_blank"}.

Our recommendation is to always run the latest (*) version of
[Minikube](https://github.com/kubernetes/minikube/){:target="_blank"}
available for your platform of choice, following their
[installation intructions](https://kubernetes.io/docs/tasks/tools/install-minikube/){:target="_blank"}. For instance, to write this guide, the **Linux** version has been used, together
with the [**KVM2**](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver){:target="_blank"}
driver.

_(*): KubeVirt >=v0.9.2 won't run on Minikube <v0.35.0 by default because of lack of vhost-net device. (see more details at [Issue#2056](https://github.com/kubevirt/kubevirt/issues/2056))_

Finally, you'll need *kubectl* installed (*), it can be downloaded from [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl){:target="_blank"} or installed using the means available for your platform.

_(*): Ensure that *kubectl* version complies with the [supported release skew](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/release/versioning.md#supported-releases-and-component-skew) (The version of kubectl should be close to Kubernetes server version)._

### Start Minikube

Before starting with Minikube, let's verify whether nested virtualization is enabled on the
host where Minikube is being installed on:

```bash
{% include scriptlets/quickstart_minikube/00_verify_nested_virt.sh -%}
```

If you get an **N**, follow the instructions described [here](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/index.html){:target="_blank"} for enabling it.

**Note** that nested virtualization is not mandatory for testing KubeVirt, but makes things smoother. If for any reason it can't be enabled, don't forget to enable emulation as shown in the *Check for the Virtualization Extensions* section.

Let's begin, normally, Minikube can be started with default values and those will be enough
to run this quickstart guide, that being said, if you can spare few more GiBs
of RAM (by default it uses 2GiB), it'll allow you to experiment further this guide.

We'll create a profile for KubeVirt so it gets its own settings without
interfering what any configuration you might had already, let's start by
increasing the default memory:

```bash
{% include scriptlets/quickstart_minikube/01_minikube_config_memory.sh -%}
```

Now, set the VM driver to KVM2:

```bash
{% include scriptlets/quickstart_minikube/02_minikube_config_vm_driver.sh -%}
```

We're ready to start the Minikube VM:

```bash
{% include scriptlets/quickstart_minikube/03_start_minikube.sh -%}
```

### Deploy KubeVirt Operator

Having the Minikube VM is up and running, let's set the *version* environment
variable that will be used on few commands:

```bash
{% include scriptlets/quickstart_minikube/04_setenv_version.sh -%}
```

Now, using the `kubectl` tool, let's deploy the KubeVirt Operator:

```bash
{% include scriptlets/quickstart_minikube/05_deploy_operator.sh -%}
```

Check it's running:

```bash
{% include scriptlets/quickstart_minikube/06_check_operator_running.sh -%}

NAME                             READY     STATUS              RESTARTS   AGE
virt-operator-6c5db798d4-9qg56   0/1       ContainerCreating   0          12s
...
virt-operator-6c5db798d4-9qg56   1/1       Running   0         28s
```

We'll need to execute the command above few times (or add *-w* for *watching*
the pods), until the operator is *Running* and *Ready* (1/1), then it's time
to head to the next section.

### Check for the Virtualization Extensions

To check if your VM's CPU supports virtualization extensions execute the
following command:

```bash
{% include scriptlets/quickstart_minikube/07_verify_virtualization.sh -%}
```

If the command doesn't generate any output, create the following *ConfigMap*
so that KubeVirt uses emulation mode, otherwise skip to the next section:

```bash
{% include scriptlets/quickstart_minikube/08_emulate_vm_extensions.sh -%}
```

### Deploy KubeVirt

KubeVirt is then deployed by creating a dedicated custom resource:

```bash
{% include scriptlets/quickstart_minikube/09_deploy_kubevirt.sh -%}
```

Check the deployment:

```bash
{% include scriptlets/quickstart_minikube/06_check_operator_running.sh -%}

NAME                               READY     STATUS    RESTARTS   AGE
virt-api-649859444c-fmrb7          1/1       Running   0          2m12s
virt-api-649859444c-qrtb6          1/1       Running   0          2m12s
virt-controller-7f49b8f77c-kpfxw   1/1       Running   0          2m12s
virt-controller-7f49b8f77c-m2h7d   1/1       Running   0          2m12s
virt-handler-t4fgb                 1/1       Running   0          2m12s
virt-operator-6c5db798d4-9qg56     1/1       Running   0          6m41s
```

Once we applied the *Custom Resource* the operator took care of deploying the
actual KubeVirt pods (*virt-api*, *virt-controller* and *virt-handler*). Again
we'll need to execute the command until everything is *up&running*
(or use *-w*).

### Install virtctl

An additional binary is provided to get quick access to the serial and graphical ports of a VM, and handle start/stop operations.
The tool is called *virtctl* and can be retrieved from the release page of KubeVirt:

```bash
{% include scriptlets/quickstart_minikube/11_get_virtctl.sh -%}
```

If [`krew` plugin manager](https://krew.dev/) is [installed](https://github.com/kubernetes-sigs/krew/#installation), `virtctl` can be installed via `krew`:

```bash
$ kubectl krew install virt
```

Then `virtctl` can be used as a kubectl plugin. For a list of available commands run:

```bash
$ kubectl virt help
```

Every occurrence throughout this guide of

```bash
$ ./virtctl <command>...
```

should then be read as

```bash
$ kubectl virt <command>...
```

### Clean Up (after lab cleanups):

Delete the Kubevirt from minikube:

```bash
{% include scriptlets/quickstart_minikube/22_minikube_delete.sh -%}
```

## Step 2: KubeVirt labs

After you have connected to your instance through SSH, you can
work through a couple of labs to help you get acquainted with KubeVirt
and how to use it to create and deploy VMs with Kubernetes.

The first lab is ["Use KubeVirt"](../labs/kubernetes/lab1). This lab walks you
through the creation of a Virtual Machine instance on Kubernetes and then
shows you how to use virtctl to interact with its console.

The second lab is ["Experiment with CDI"](../labs/kubernetes/lab2). This
lab shows you how to use the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer){:target="_blank"}
(CDI) to import a VM image into a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/){:target="_blank"}
(PVC) and then how to define a VM to make use of the PVC.

## Found a bug?

We are interested in hearing about your experience.

If you encounter an issue with deploying your cloud instance or if
Kubernetes or KubeVirt did not install correctly, please report it to
the [cloud-image-builder issue tracker](https://github.com/kubevirt/cloud-image-builder/issues){:target="_blank"}.

If experience a problem with the labs, please report it to the [kubevirt.io issue tracker](https://github.com/kubevirt/kubevirt.github.io/issues){:target="_blank"}.
