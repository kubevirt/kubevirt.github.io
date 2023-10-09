---
layout: labs
title: KubeVirt quickstart with Minikube
permalink: /quickstart_minikube/
navbar_active: Labs
redirect_from: "/get_kubevirt/"
order: 2
lab: minikube
tags:
  [
    "Kubernetes",
    "minikube",
    "minikube addons",
    "kubevirt",
    "VM",
    "virtual machine",
  ]
---

## Easy install using minikube

[Minikube](https://minikube.sigs.k8s.io/docs/start/) quickly sets up a local Kubernetes cluster on macOS, Linux, and Windows allowing software developers to quickly get started working with Kubernetes.


## Prepare minikube Kubernetes environment

{% include quickstarts/kubectl.md %}

Minikube ships a kubectl client version that matches the kubernetes version to avoid skew issues. To use the minikube shipped client do one of the following:

* All normal `kubectl` commands should be performed as `minikube kubectl`
* It can be added to aliases by running the following:

  ```bash
  alias kubectl='minikube kubectl --'
  ```

* It can be installed directly to the host by running the following:

  ```bash
  VERSION=$(minikube kubectl version | head -1 | awk -F', ' {'print $3'} | awk -F':' {'print $2'} | sed s/\"//g)
  sudo install ${HOME}/.minikube/cache/linux/${VERSION}/kubectl /usr/local/bin
  ```

* To install minikube please follow the official documentation for your system using the instructions located [_here_](https://kubernetes.io/docs/tasks/tools/install-minikube/).

* Starting minikube can be as simple as running the following command:

  ```bash
  minikube start --cni=flannel
  ```

  > info "CNI:"
  > We add the container network interface (CNI) called [flannel](https://github.com/flannel-io/flannel/blob/master/README.md) to make minikube work with VMs that use a masquerade type network interface. If a CNI does not work for you, switch instances of "masquerade" to "bridge" in example VM definitions.

  > info ""
  > See the minikube handbook [_here_](https://minikube.sigs.k8s.io/docs/) for advanced start options and instructions on how to operate minikube.

{% include quickstarts/multi_node_minikube.md %}

> warning "Core DNS race condition"
> An issue has been
> [reported](https://github.com/kubernetes/minikube/issues/11608) where the
> `coredns` pod in multi-node minikube comes up with the wrong IP address. If
> this happens, kubevirt will fail to install properly. To work around, delete
> the `coredns` pod from the kube-system namespace and disable/enable the
> kubevirt addon in minikube.

## Deploy KubeVirt

KubeVirt can be installed using the KubeVirt operator, which manages the lifecycle of all the KubeVirt core components.

Below are two examples of how to install KubeVirt using the latest release.

### The easy way

> warning "Addon currently broken"
> An issue has been [reported](https://github.com/kubernetes/minikube/issues/15918) where more recent versions of minikube break the kubevirt addon. Fall back to the "in-depth" section below until this is resolved.

* Installing KubeVirt can be as simple as the following command:

  ```bash
  minikube addons enable kubevirt
  ```

### The in-depth way

* Use `kubectl` to deploy the KubeVirt operator:

  ```bash
  export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
  echo $VERSION
  kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml
  ```

> warning "Nested virtualization"
> If the minikube cluster runs on a virtual machine consider enabling nested virtualization.  Follow the instructions described [here](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/index.html){:target="\_blank"}.
> If for any reason nested virtualization cannot be enabled do enable KubeVirt emulation as follows:
>
> ```bash
> kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'
> ```

* Again use `kubectl` to deploy the KubeVirt custom resource definitions:

  ```bash
  kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml
  ```

### Verify components

By default KubeVirt will deploy 7 pods, 3 services, 1 daemonset, 3 deployment apps, 3 replica sets.

* Check the deployment:

  ```bash
  kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
  ````

* Check the components:

  ```bash
  kubectl get all -n kubevirt
  ```

* When using the minikube KubeVirt addon check logs of the kubevirt-install-manager pod:

  ```bash
  kubectl logs pod/kubevirt-install-manager -n kube-system
  ```

{% include quickstarts/virtctl.md %}

{% include labs-description.md %}

{% include found_a_bug.md %}
