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
{% include scriptlets/lab1/01_get_vm_manifest.sh -%}
less vm.yaml
```

Apply the manifest to Kubernetes.

```bash
{% include scriptlets/lab1/02_create_testvm.sh -%}
  virtualmachine.kubevirt.io "testvm" created
  virtualmachineinstancepreset.kubevirt.io "small" created
```

### Manage Virtual Machines (optional):

To get a list of existing Virtual Machines. Note the `running` status.

```
{% include scriptlets/lab1/03_verify_testvm.sh -%}
```

To start a Virtual Machine you can use:

```
{% include scriptlets/lab1/04_start_testvm.sh -%}
```

If you installed virtctl via krew, you can use `kubectl virt`:

```shell
# Start the virtual machine:
kubectl virt start testvm

# Stop the virtual machine:
kubectl virt stop testvm
```

Alternatively you could use `kubectl patch`:

```shell
# Start the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

# Stop the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'
```

Now that the Virtual Machine has been started, check the status. Note the `running` status.

```
{% include scriptlets/lab1/05_verify_testvm_instance.sh -%}
```

### Accessing VMs (serial console)

Connect to the serial console of the Cirros VM. Hit return / enter a few times and login with the displayed username and password.

```
{% include scriptlets/lab1/06_connect_to_testvm_console.sh -%}
```

Disconnect from the virtual machine console by typing: `ctrl+]`.

### Controlling the State of the VM

To shut it down:

```
{% include scriptlets/lab1/07_stop_testvm.sh -%}
```

To delete a Virtual Machine:

```
{% include scriptlets/lab1/08_delete_testvm.sh -%}
```

This concludes this section of the lab.

[Next Lab]({{ site.baseurl }}/labs/kubernetes/lab2)
