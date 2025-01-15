---
layout: labs
title: Use KubeVirt
permalink: /labs/kubernetes/lab1
navbar_active: Labs
lab: kubernetes
order: 1
tags:
  [
    laboratory,
    kubevirt installation,
    start vm,
    stop vm,
    delete vm,
    access console,
    lab,
  ]
---

# Use KubeVirt

- You can experiment with this lab online at [Killercoda](https://killercoda.com/kubevirt/scenario/kubevirt-101)

### Create a Virtual Machine

Download the VM manifest and explore it. Note it uses a [container disk](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#containerdisk) and as such doesn't persist data. Such container disks currently exist for alpine, cirros and fedora.

```bash
{% include scriptlets/lab1/01_get_vm_manifest.sh -%}
less vm.yaml
```

Apply the manifest to Kubernetes.

```bash
{% include scriptlets/lab1/02_create_testvm.sh -%}
```

You should see following result
> virtualmachine.kubevirt.io "testvm" created

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
kubectl patch virtualmachine testvm --type merge -p \
    '{"spec":{"runStrategy": "Always"}}'

# Stop the virtual machine:
kubectl patch virtualmachine testvm --type merge -p \
    '{"spec":{"runStrategy": "Halted"}}'
```

Now that the Virtual Machine has been started, check the status (`kubectl get vms`). Note the `Running` status.

You now want to see the instance of the vm you just started :

```
{% include scriptlets/lab1/05_verify_testvm_instance.sh -%}
```

Note the difference between VM (virtual machine) resource and VMI (virtual machine instance) resource. The VMI does not exist before starting the VM and the VMI will be deleted when you stop the VM. (Also note that restart of the VM is needed if you like to change some properties. Just modifying VM is not sufficient, the VMI has to be replaced.) 

### Accessing VMs (serial console)

Connect to the serial console of the Cirros VM. Hit return / enter a few times and login with the displayed username and password.

```
{% include scriptlets/lab1/06_connect_to_testvm_console.sh -%}
```

Disconnect from the virtual machine console by typing: `ctrl+]`.

If you like to see the complete boot sequence logs from the console. You need to connect to the serial console just after starting the VM (you can test this by stopping and starting the VM again, see below).

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

You can watch how the laboratory is done in the following video:

<iframe width="560" height="315" style="height: 315px" src="https://www.youtube.com/embed/eQZPCeOs9-c" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Next Lab]({{ site.baseurl }}/labs/kubernetes/lab2)
