---
layout: labs
title: KubeVirt quickstart with cloud providers
permalink: /quickstart_cloud/
redirect_from: "/get_kubevirt/"
order: 2
lab: cloud provider
tags: [
  "AliCloud",
  "Amazon",
  "AWS",
  "Google",
  "GCP",
  "Kubernetes",
  "KubeVirt",
  "quickstart",
  "tutorial",
  "VM",
  "virtual machine",
  ]
---

## Easy install using cloud providers

KubeVirt can be used on cloud computing providers such as AWS, Azure, GCP, AliCloud.

## Prepare a cloud based Kubernetes cluster

{% include quickstarts/kubectl.md %}

* Check the Kubernetes.io [Turnkey Cloud Solutions guide](https://kubernetes.io/docs/setup/production-environment/turnkey-solutions) for each cloud provider on how to build infrastructure to match your use case.

> error ""
> Be aware of the costs of associated with using infrastructure provided by cloud computing providers.
<a/>
> info ""
> Future labs will require at least 30 GiB of disk space.

## Deploy KubeVirt

KubeVirt can be installed using the KubeVirt operator, which manages the lifecycle of all the KubeVirt core components.

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
  >```bash
  >kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'
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
  ```

* Check the components:

  ```bash
  kubectl get all -n kubevirt
  ```

{% include quickstarts/virtctl.md %}

{% include labs-description.md %}

{% include found_a_bug.md %}
