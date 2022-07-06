---
layout: labs
title: KubeVirt Upgrades
permalink: /labs/kubernetes/lab3
navbar_active: Labs
lab: kubernetes
order: 1
tags: [laboratory, kubevirt upgrades, upgrade, lifecycle, lab]
---

# Experiment with KubeVirt Upgrades

#### Deploy KubeVirt

**_NOTE_**: For upgrading to the latest KubeVirt version, first we will install a specific older version of the operator, if you're already using latest, please start with an older KubeVirt version and follow [Lab1]({{ site.baseurl }}/labs/kubernetes/lab1) to deploy KubeVirt on it, but using version `v0.20.1` instead.

If you've already covered this, jump over this section.

Let's stick to use the release `v0.20.1`:

```sh
export KUBEVIRT_VERSION=v0.20.1
```

Let's deploy the KubeVirt Operator by running the following command:

```sh
$ kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
namespace/kubevirt created
...
deployment.apps/virt-operator created
```

Let's wait for the operator to become ready:

```sh
$ kubectl wait --for condition=ready pod -l kubevirt.io=virt-operator -n kubevirt --timeout=100s
pod/virt-operator-5ddb4674b9-6fbrv condition met
```

If you're running in a virtualized environment, in order to be able to run VMs here we need to pre-configure KubeVirt so it uses software-emulated virtualization instead of trying to use real hardware virtualization.

```sh
$ kubectl create configmap kubevirt-config -n kubevirt --from-literal debug.useEmulation=true
configmap/kubevirt-config created
```

Now let's deploy KubeVirt by creating a Custom Resource that will trigger the 'operator' and perform the deployment:

```sh
$ kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
kubevirt.kubevirt.io/kubevirt created
```

Let's check the deployment:

```sh
$ kubectl get pods -n kubevirt
```

Once it's ready, it will show something similar to the information below:

```sh
$ kubectl get pods -n kubevirt
NAME                               READY     STATUS    RESTARTS   AGE
virt-api-7fc57db6dd-g4s4w          1/1       Running   0          3m
virt-api-7fc57db6dd-zd95q          1/1       Running   0          3m
virt-controller-6849d45bcc-88zd4   1/1       Running   0          3m
virt-controller-6849d45bcc-cmfzk   1/1       Running   0          3m
virt-handler-fvsqw                 1/1       Running   0          3m
virt-operator-5649f67475-gmphg     1/1       Running   0          4m
virt-operator-5649f67475-sw78k     1/1       Running   0          4m
```

#### Deploy a VM

Once all the containers are with the status "Running" you can execute the command below for applying a YAML definition of a virtual machine into our current Kubernetes environment:

First, let's wait for all the pods to be ready like previously provided example:

```sh
$ kubectl wait --for condition=ready pod -l kubevirt.io=virt-api -n kubevirt --timeout=100s
pod/virt-api-5ddb4674b9-6fbrv condition met
$ kubectl wait --for condition=ready pod -l kubevirt.io=virt-controller -n kubevirt --timeout=100s
pod/virt-controller-p3d4o-1fvfz condition met
$ kubectl wait --for condition=ready pod -l kubevirt.io=virt-handler -n kubevirt --timeout=100s
pod/virt-handler-1b4n3z4674b9-sf1rl condition met
```

And proceed with the VM creation:

```sh
$ kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml
virtualmachine.kubevirt.io/testvm created
```

Using the command below for checking that the VM is defined:

```sh
$ kubectl get vms
NAME    AGE RUNNING VOLUME
testvm  22s false
```

Notice from the output that the VM is not running yet.

To start a VM, `virtctl`~~~` should be used:

```sh
$ virtctl start testvm
VM testvm was scheduled to start
```

Now you can check again the VM status:

```sh
$ kubectl get vms
NAME     AGE   RUNNING   VOLUME
testvm   0s    false
```

Once the VM is running you can inspect its status:

```sh
kubectl get vmis
$ kubectl get vmis
NAME     AGE   PHASE        IP    NODENAME
testvm   10s   Scheduling
```

Once it's ready, the command above will print something like:

```sh
$ kubectl get vmis
NAME      AGE       PHASE     IP           NODENAME
testvm    1m        Running   10.32.0.11   master
```

While the PHASE is still `Scheduling` you can run the same command for checking again:

```sh
$ kubectl get vmis
```

Once the PHASE will change to `Running`, we're ready for upgrading KubeVirt.

#### Define the next version to upgrade to

KubeVirt starting from `v0.17.0` onwards, allows to upgrade one version at a time, by using two approaches as defined in the [user-guide](https://kubevirt.io/user-guide/operations/updating_and_deletion):

- Patching the imageTag value in the KubeVirt CR spec
- Updating the operator if no imageTag is defined (defaulting to upgrade to match the operator version)

**WARNING:** In both cases, the supported scenario is updating from N-1 to N

**NOTE:** Zero downtime rolling updates are supported starting with release `v0.17.0` onwards. Updating from any release prior to the KubeVirt `v0.17.0` release is not supported.

#### Performing the upgrade

##### Updating the KubeVirt operator if no imageTag value is set

When no `imageTag` value is set in the KubeVirt CR, the system assumes that the version of KubeVirt is locked to the version of the operator. This means that updating the operator will result in the underlying KubeVirt installation being updated as well.

Let's upgrade to the newer version after the one installed (`0.20.1` -> `0.21.0`):

```sh
$ export KUBEVIRT_VERSION=v0.21.0
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
...
deployment.apps/virt-operator configured
```

**NOTE:** Compared to the first step of the lab now we are using **apply** instead of **create** to deploy the newer version because the operator already exists.

In any case, we can check that the VM is still running

```sh
$ kubectl get vmis
NAME      AGE       PHASE     IP           NODENAME
testvm    1m        Running   10.32.0.11   master
```

#### Final upgrades

You can keep testing in this lab updating 'one version at a time' until reaching the value of `KUBEVIRT_LATEST_VERSION`:

```sh
$ export KUBEVIRT_LATEST_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | jq -r .tag_name)
$ echo -e "CURRENT: $KUBEVIRT_VERSION  LATEST: $KUBEVIRT_LATEST_VERSION"
```

Compare the values between and continue upgrading 'one release at a time' by:

Choosing the target version:

```sh
$ export KUBEVIRT_VERSION=vX.XX.X
```

Updating the operator to that release:

```sh
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
...
deployment.apps/virt-operator configured
```

**NOTE:** Since version `0.20.1`, the operator version should be checked with the following command:

```sh
$ echo $(kubectl get deployment.apps virt-operator -n kubevirt -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KUBEVIRT_VERSION")].value}')
```

#### Wrap-up

Shutting down a VM works by either using `virtctl` or editing the VM.

```sh
$ virtctl stop testvm
VM testvm was scheduled to stop
```

Finally, the VM can be deleted using:

```sh
$ kubectl delete vms testvm
virtualmachine.kubevirt.io "testvm" deleted
```

When updating using the operator, we can see that the 'AGE' of containers is similar between them, but when updating only the kubevirt version, the operator 'AGE' keeps increasing because it is not 'recreated'.

This concludes this section of the lab.

You can watch how the laboratory is done in the following video:

<iframe width="560" height="315" style="height: 315px" src="https://www.youtube.com/embed/OAPzOvqp0is" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Previous Lab]({{ site.baseurl }}/labs/kubernetes/lab2)
