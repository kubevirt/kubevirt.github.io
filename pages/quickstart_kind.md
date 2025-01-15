---
layout: labs
title: KubeVirt quickstart with kind
permalink: /quickstart_kind/
navbar_active: Labs
redirect_from: "/get_kubevirt/"
order: 2
lab: kind
tags:
  [
    "Kubernetes",
    "kind",
    "kubevirt",
    "VM",
    "virtual machine",
  ]
---

## Easy install using kind

Kind quickly sets up a local Kubernetes cluster on macOS, Linux, and Windows allowing software developers to quickly get started working with Kubernetes.

## Prepare kind Kubernetes environment

{% include quickstarts/kubectl.md %}

* To install kind please follow the official documentation for your system using the instructions located [_here_](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

* Starting kind can be as simple as running the following command:

  ```bash
  kind create cluster
  ```

> info ""
> See the kind User Guide [_here_](https://kind.sigs.k8s.io/) for advanced start options and instructions on how to operate kind.

## Deploy KubeVirt

KubeVirt can be installed using the KubeVirt operator, which manages the lifecycle of all the KubeVirt core components.

* Use `kubectl` to deploy the KubeVirt operator:

  ```bash
  export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

  echo $VERSION
  kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
  ```

  > warning "Nested virtualization"
  > If the kind cluster runs on a virtual machine consider enabling nested virtualization.  Follow the instructions described [here](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/index.html){:target="\_blank"}.
  > If for any reason nested virtualization cannot be enabled do enable KubeVirt emulation as follows:
  >
  >```bash
  >kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'
  >```

* Again use `kubectl` to deploy the KubeVirt custom resource definitions:

  ```bash
  kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
  ```

### Verify components

By default KubeVirt will deploy 6 pods, 4 services, 1 daemonset, 3 deployment apps, 3 replica sets.

* Check the deployment:

  ```bash
  kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
  ````

* Check the components:

  ```bash
  kubectl get all -n kubevirt
  ```

{% include quickstarts/virtctl.md %}

{% include labs-description.md %}

{% include found_a_bug.md %}
