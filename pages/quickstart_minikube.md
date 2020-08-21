---
layout: labs
title: KubeVirt Quickstart with Minikube
permalink: /quickstart_minikube/
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

# Easy install using minikube

Minikube quickly sets up a local Kubernetes cluster on macOS, Linux, and Windows allowing software developers to quickly get started working with Kubernetes.

## Prepare minikube Kubernetes environment

* To install minikube please follow the official documentation for your system using the instructions located [_here_](https://kubernetes.io/docs/tasks/tools/install-minikube/){:target="\_blank"}.

* Starting minikube can be as simple as running the following command:
```
minikube start
```

    > info "Minikube handbook"
    > See the minikube handbook [_here_](https://minikube.sigs.k8s.io/docs/) for advanced start options and instructions on how to operate minikube.

* A kubectl client is necessary for operating a Kubernetes cluster. Minikube ships a  kubectl client version that matches the kubernetes version to avoid issues regarding [_skew_](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/release/versioning.md#supported-releases-and-component-skew).<br><br>
To use the minikube shipped client all normal `kubectl` commands should be performed as `minikube kubectl`.<br><br>
Or the shipped client can be added to aliases by running the following:
```bash
alias kubectl='minikube kubectl --'
```
<br>Or installed directly to the host by running the following:
```bash
VERSION=$(minikube kubectl version | head -1 | awk -F', ' {'print $3'} | awk -F':' {'print $2'} | sed s/\"//g)
sudo install ${HOME}/.minikube/cache/linux/${VERSION}/kubectl /usr/local/bin
```

## Deploy KubeVirt

KubeVirt can be installed using the KubeVirt operator, which manages the lifecycle of all the KubeVirt core components. Below are two examples of how to install KubeVirt using the latest release.

### The easy way

* Installing KubeVirt can be as simple as the following command:
```
minikube addons enable kubevirt
```

### The in-depth way

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

* When using the minikube KubeVirt addon check logs of the kubevirt-install-manager pod:
```
kubectl logs pod/kubevirt-install-manager -n kube-system
```

## Virtctl

KubeVirt provides an additional binary called _virtctl_ for quick access to the serial and graphical ports of a VM and also handle start/stop operations.

### Install
`virtctl` can be retrieved from the release page of the KubeVirt github page.

* Run the following:
   ```bash
VERSION=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
ARCH=darwin-amd64 | linux-amd64 | windows-amd64.exe
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
chmod +x virtctl
sudo install virtctl /usr/local/bin
```
<br>

### Install as Krew plugin
`virtctl` can be installed as a plugin via the [`krew` plugin manager](https://krew.dev/). Occurrences of `virtctl <command>...` can then be read as `kubectl virt <command>...`.  

* Run the following to install:
```bash
kubectl krew install virt
```
<br>

{% include labs-description.md %}

{% include found_a_bug.md %}
