---
layout: labs
title: KubeVirt Quickstart with Kind
permalink: /quickstart_kind/
order: 2
lab: kubernetes
tags: [kind, quickstart, tutorial]
---

# Easy install using Kind

Kind (Kubernetes in Docker) is a tool for running local Kubernetes clusters using Docker container "nodes".

Kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.

In Step 1, we guide you through setting up your environment to launch Kubernetes via Kind

After it's ready, dive into the two labs below to help you get
acquainted with KubeVirt.

## Step 1: Prepare Kind environment

This guide will help you deploying [KubeVirt](https://kubevirt.io) on
Kubernetes, we'll be using
[Kind](https://github.com/kubernetes-sigs/kind){:target="\_blank"}.

If you have [go](https://golang.org/) ([1.11+](https://golang.org/doc/devel/release.html#policy)) and [docker](https://www.docker.com/)
already installed the following command is all you need:

```bash
GO111MODULE="on" go get sigs.k8s.io/kind@v0.7.0 && kind create cluster
```

> note "Note"
> Please use the latest `go` to do this, ideally go 1.13 or greater.

This will put kind in $(go env GOPATH)/bin. If you encounter the error kind: command not found after installation then you may need to
either add that directory to your $PATH as shown [here](https://golang.org/doc/code.html#GOPATH) or do a manual installation by cloning
the repo and run make build from the repository.

Stable binaries are also available on the [releases](https://github.com/kubernetes-sigs/kind/releases) page. Stable releases are generally
recommended for CI usage in particular. To install, download the binary for your platform from "Assets" and place this into your `$PATH`:

```bash
curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-$(uname)-amd64"
chmod +x ./kind
mv ./kind /some-dir-in-your-PATH/kind
```

Our recommendation is to always run the latest (\*) version of
[Kind](https://github.com/kubernetes-sigs/kind){:target="\_blank"}
available for your platform of choice, following their
[quick start](https://kind.sigs.k8s.io/docs/user/quick-start/){:target="\_blank"}.

To use kind, you will need to install [docker](https://docs.docker.com/install/).

Finally, you'll need _kubectl_ installed (\*), it can be downloaded from [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl){:target="\_blank"} or installed using the means available for your platform.

_(*): Ensure that *kubectl\* version complies with the [supported release skew](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/release/versioning.md#supported-releases-and-component-skew) (The version of kubectl should be close to Kubernetes server version)._

### Start Kind

Before starting with Kind, let's verify whether nested virtualization is enabled on the
host where Kind is being installed on:

```bash
{% include scriptlets/quickstart_kind/00_verify_nested_virt.sh -%}
```

If you get an **N**, follow the instructions described [here](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/index.html){:target="\_blank"} for enabling it.

> note "Note"
> Nested virtualization is not mandatory for testing KubeVirt, but makes things smoother. If for any reason it can't be enabled,
> don't forget to enable emulation as shown in the _[Check for the Virtualization Extensions](#check-for-the-virtualization-extensions)_ section.

Let's begin, normally, Kind can be started with default values and those will be enough
to run this quickstart guide.

For example to create a basic cluster of 1 node you can use the following command:

```bash
$ kind create cluster # Default cluster context name is `kind`.
```

If you want to have multiple clusters in the same server you can name them with the `--name` parameter:

```bash
$ kind create cluster --name kind
```

To retrieve the existing clusters you can execute the following commands:

```bash
$ kind get clusters
kind
```

In order to interact with a specific cluster, you only need to specify the cluster name as a context in kubectl:

```bash
$ kubectl cluster-info --context kind-kind
```

We're ready to create the cluster with Kind, in this case we are using a cluster with one control-plane and two workers:

```bash
{% include scriptlets/quickstart_kind/01_setup_cluster.sh -%}
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.17.0) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
```

### Deploy KubeVirt Operator

Having the Kind cluster up and running, let's set the _version_ environment
variable that will be used on few commands:

```bash
{% include scriptlets/quickstart_kind/02_setenv_version.sh -%}
```

Now, using the `kubectl` tool, let's deploy the KubeVirt Operator:

```bash
{% include scriptlets/quickstart_kind/03_deploy_operator.sh -%}
```

Check that it's running:

```bash
{% include scriptlets/quickstart_kind/04_check_operator_running.sh -%}

NAME                             READY     STATUS              RESTARTS   AGE
virt-operator-6c5db798d4-9qg56   0/1       ContainerCreating   0          12s
...
virt-operator-6c5db798d4-9qg56   1/1       Running   0         28s
```

We can execute the command above few times or add the (_-w_) flag for _watching_
the pods until the operator is in _Running_ and _Ready_ (1/1) status, then it's time
to head to the next section.

### Check for the Virtualization Extensions

To check if your CPU supports virtualization extensions execute the
following command:

```bash
{% include scriptlets/quickstart_kind/05_verify_virtualization.sh -%}
```

If the command doesn't generate any output, create the following _ConfigMap_
so that KubeVirt uses emulation mode, otherwise skip to the next section:

```bash
{% include scriptlets/quickstart_kind/06_emulate_vm_extensions.sh -%}
```

### Deploy KubeVirt

KubeVirt is then deployed by creating a dedicated custom resource:

```bash
{% include scriptlets/quickstart_kind/07_deploy_kubevirt.sh -%}
```

Check the deployment:

```bash
{% include scriptlets/quickstart_kind/04_check_operator_running.sh -%}

NAME                               READY     STATUS    RESTARTS   AGE
virt-api-649859444c-fmrb7          1/1       Running   0          2m12s
virt-api-649859444c-qrtb6          1/1       Running   0          2m12s
virt-controller-7f49b8f77c-kpfxw   1/1       Running   0          2m12s
virt-controller-7f49b8f77c-m2h7d   1/1       Running   0          2m12s
virt-handler-t4fgb                 1/1       Running   0          2m12s
virt-operator-6c5db798d4-9qg56     1/1       Running   0          6m41s
```

Once we applied the KubeVirt's _Custom Resource_ the operator took care of deploying the
actual KubeVirt pods (_virt-api_, _virt-controller_ and _virt-handler_). Again
we'll need to execute the command until everything is _up and running_
(or use the _-w_ flag).

### Install virtctl

An additional binary is provided to get quick access to the serial and graphical ports of a VM, and handle start/stop operations.
The tool is called _virtctl_ and can be retrieved from the release page of KubeVirt:

```bash
{% include scriptlets/quickstart_kind/08_get_virtctl.sh -%}
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

Delete the Kubernetes cluster with kind:

```bash
{% include scriptlets/quickstart_kind/99_kind_delete.sh -%}
```

## Step 2: KubeVirt labs

After you have connected to your instance through SSH, you can
work through a couple of labs to help you get acquainted with KubeVirt
and how to use it to create and deploy VMs with Kubernetes.

The first lab is ["Use KubeVirt"](../labs/kubernetes/lab1). This lab walks
through the creation of a Virtual Machine Instance (VMI) on Kubernetes and then
it is shown how virtctl is used to interact with its console.

The second lab is ["Experiment with CDI"](../labs/kubernetes/lab2). This
lab shows how to use the [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer){:target="\_blank"}
(CDI) to import a VM image into a [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/){:target="\_blank"}
(PVC) and then how to define a VM to make use of the PVC.

The third lab is ["KubeVirt upgrades"](../labs/kubernetes/lab3). This lab shows
how easy and safe is to upgrade your KubeVirt installation with zero down-time.

## Found a bug?

We are interested in hearing about your experience.

If you encounter an issue with deploying your cloud instance or if
Kubernetes or KubeVirt did not install correctly, please report it to
the [cloud-image-builder issue tracker](https://github.com/kubevirt/cloud-image-builder/issues){:target="\_blank"}.

If experience a problem with the labs, please report it to the [kubevirt.io issue tracker](https://github.com/kubevirt/kubevirt.github.io/issues){:target="\_blank"}.
