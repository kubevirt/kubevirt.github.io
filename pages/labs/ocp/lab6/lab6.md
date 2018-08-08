## Use KubeVirt

### Create a Virtual Machine

Download the VM manifest and explore it. Note it uses a [registry disk](https://kubevirt.io/user-guide/#/workloads/virtual-machines/disks-and-volumes?id=registrydisk) and as such doesn't persist data. Such registry disks currently exist for alpine, cirros and fedora.

```
wget https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
less vm.yaml
```

Apply the manifest to OpenShift.

```
oc apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
  virtualmachine.kubevirt.io "testvm" created
  virtualmachineinstancepreset.kubevirt.io "small" created
```

### Manage Virtual Machines (optional):

To get a list of existing Virtual Machines. Note the `running` status.

```
oc get vms
oc get vms -o yaml testvm
```

To start a Virtual Machine you can use:

```
./virtctl start testvm
```

Now that the Virtual Machine has been started, check the status. Note the `running` status.

```
oc get vms
oc get vms -o yaml testvm
```

### Accessing VMs (serial console & spice)

Connect to the serial console of the Cirros VM. Hit return / enter a few times and login with the displayed username and password. 

```
./virtctl console testvm
```

### Communication Between Application and Virtual Machine

While in the console of the `testvm` let's run `curl` to confirm our virtual machine
can access the `Service` of the application deployment.

```
curl ara.myproject.svc.cluster.local:8080
```

The expected output from the curl command should be:

```
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>Redirecting...</title>
<h1>Redirecting...</h1>
<p>You should be redirected automatically to target URL: <a href="/about/">/about/</a>.  If not click the link.
```

Disconnect from the virtual machine console by typing: `ctrl+]`.

Connect to the graphical display.

Note: Requires `remote-viewer` from the `virt-viewer` package. This is out of scope for this lab. 

```
./virtctl vnc testvm
```

### Controlling the State of the VM

To shut it down:

```
./virtctl stop testvm
```

To delete a Virtual Machine:

```
oc delete vms testvm
```

This concludes this section of the lab.

[Next Lab](../lab7/lab7.md)\
[Previous Lab](../lab5/lab5.md)\
[Home](../../README.md)
