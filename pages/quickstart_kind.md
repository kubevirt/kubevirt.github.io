---
layout: labs
title: KubeVirt quickstart with kind
permalink: /quickstart_kind/
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

# Easy install using kind

Kind quickly sets up a local Kubernetes cluster on macOS, Linux, and Windows allowing software developers to quickly get started working with Kubernetes.

## Prepare kind Kubernetes environment

* A kubectl client is necessary for operating a Kubernetes cluster. It is important to install a  kubectl client version that matches the kubernetes version to avoid issues regarding [_skew_](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/release/versioning.md#supported-releases-and-component-skew).
<br><br>
To install kubectl client please follow the official documentation for your system using the instructions located [_here_](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

* To install kind please follow the official documentation for your system using the instructions located [_here_](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

* Starting kind can be as simple as running the following command:
```
kind create cluster
```

> info ""
> See the kind User Guide [_here_](https://kind.docs.kubernetes.io/) for advanced start options and instructions on how to operate kind.

## Deploy KubeVirt

KubeVirt can be installed using the KubeVirt operator, which manages the lifecycle of all the KubeVirt core components.

* Use `kubectl` to deploy the KubeVirt operator:
```
export VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
echo $VERSION
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml
```

  > warning "Nested virtualization"
  > If the minikube cluster runs on a virtual machine consider enabling nested virtualization.  Follow the instructions described [here](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/index.html){:target="\_blank"}.
  >
  > If for any reason nested virtualization cannot be enabled do enable KubeVirt emulation as follows:
  >```bash
  > kubectl create configmap kubevirt-config -n kubevirt --from-literal debug.useEmulation=true
  > ```

* Again use `kubectl` to deploy the KubeVirt custom resource definitions:
```
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml
```

### Verify components

By default KubeVirt will deploy 7 pods, 3 services, 1 daemonset, 3 deployment apps, 3 replica sets.

* Check the deployment:
```
kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
````

* Check the components:
```
kubectl get all -n kubevirt
```
<br>

{% include quickstarts/virtctl.md %}

{% include labs-description.md %}

{% include found_a_bug.md %}
