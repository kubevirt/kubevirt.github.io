---
layout: labs
title: Use KubeVirt
permalink: /labs/kubernetes/lab1
lab: kubernetes
order: 1
---

# Use KubeVirt

### Create a Virtual Machine

Download the VM manifest and explore it. Note it uses a [registry disk](https://kubevirt.io/user-guide/#/workloads/virtual-machines/disks-and-volumes?id=registrydisk) and as such doesn't persist data. Such registry disks currently exist for alpine, cirros and fedora.

```bash
wget https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
less vm.yaml
```

Apply the manifest to Kubernetes.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
  virtualmachine.kubevirt.io "testvm" created
  virtualmachineinstancepreset.kubevirt.io "small" created
```

### Manage Virtual Machines (optional):

To get a list of existing Virtual Machines. Note the `running` status.

```
kubectl get vms
kubectl get vms -o yaml testvm
```

To start a Virtual Machine you can use:

```
./virtctl start testvm
```

Now that the Virtual Machine has been started, check the status. Note the `running` status.

```
kubectl get vms
kubectl get vms -o yaml testvm
```

### Accessing VMs (serial console)

Connect to the serial console of the Cirros VM. Hit return / enter a few times and login with the displayed username and password.

```
./virtctl console testvm
```

Disconnect from the virtual machine console by typing: `ctrl+]`.

### Controlling the State of the VM

To shut it down:

```
./virtctl stop testvm
```

To delete a Virtual Machine:

```
kubectl delete vms testvm
```

This concludes this section of the lab.

[Next Lab]({{ site.baseurl }}/labs/kubernetes/lab2)\
[Home]({{ site.baseurl }}/labs.html)
