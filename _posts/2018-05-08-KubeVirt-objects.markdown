---
layout: post
author: jcpowermac
description: In this post we will go over the objects provided by KubeVirt
navbar_active: Blogs
pub-date: May 08
pub-year: 2018
category: uncategorized
tags: [custom resources, kubevirt objects, objects, VirtualMachine]
comments: true
---

The [KubeVirt](https://github.com/kubevirt/kubevirt/) project provides extensions to Kubernetes via [custom resources](https://kubernetes.io/docs/concepts/api-extension/custom-resources/).

These resources are a collection a API objects that defines a virtual machine within Kubernetes.

I think it's important to point out the two great resources that I used to
compile information for this post:

- [user-guide](http://kubevirt.io/user-guide/)
- [api-reference](http://kubevirt.io/api-reference/)

With that let’s take a look at the objects that are available.

# KubeVirt top-level objects

Below is a list of the top level API objects and descriptions that KubeVirt provides.

- VirtualMachine (vm\[s\]) - represents a virtual machine in the runtime environment of Kubernetes.

- OfflineVirtualMachine (ovm\[s\]) - handles the virtual machines that are not running or are in a stopped state.

- VirtualMachinePreset (vmpreset\[s\]) - is an extension to general VirtualMachine configuration behaving much like PodPresets from Kubernetes. When a VirtualMachine is created, any applicable VirtualMachinePresets will be applied to the existing spec for the VirtualMachine. This allows for re-use of common settings that should apply to multiple VirtualMachines.

- VirtualMachineReplicaSet (vmrs\[s\]) - tries to ensures that a specified number of VirtualMachine replicas are running at any time.

[DomainSpec](http://kubevirt.io/api-reference/master/definitions.html#_v1_domainspec) is listed as a top-level object but is only used within all of the objects above. Currently the `DomainSpec` is a subset of what is configurable via [libvirt domain XML](https://libvirt.org/formatdomain.html).

## VirtualMachine

VirtualMachine is mortal object just like a
[Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod/) within Kubernetes.
It only runs once and cannot be resurrected. This might seem problematic especially
to an administrator coming from a traditional virtualization background. Fortunately
later we will discuss OfflineVirtualMachines which will address this.

First let’s use `kubectl` to retrieve a list of `VirtualMachine` objects.

    $ kubectl get vms -n nodejs-ex
    NAME      AGE
    mongodb   5d
    nodejs    5d

We can also use `kubectl describe`

```
$ kubectl describe vms -n test
Name:         testvm
Namespace:    test
Labels:       guest=testvm
              kubevirt.io/nodeName=kn2.virtomation.com
              kubevirt.io/size=small
...output...
Events:
  Type    Reason              Age                From                               Message
  ----    ------              ----               ----                               -------
  Normal  SuccessfulCreate    59m                virtualmachine-controller          Created virtual machine pod virt-launcher-testvm-8h927
  Normal  SuccessfulHandOver  59m                virtualmachine-controller          Pod owner ship transfered to the node virt-launcher-testvm-8h927
  Normal  Created             59m (x2 over 59m)  virt-handler, kn2.virtomation.com  VM defined.
  Normal  Started             59m                virt-handler, kn2.virtomation.com  VM started.

```

And just in case if you want to return the yaml definition of a `VirtualMachine` object here is an example.

    $ kubectl -o yaml get vms mongodb -n nodejs-ex
    apiVersion: kubevirt.io/v1alpha1
    kind: VirtualMachine
    ...output...

The first object we will annotate is `VirtualMachine`. The important sections `.spec` for `VirtualMachineSpec` and `.spec.domain` for `DomainSpec` will be annotated only in this section then referred to in the other object sections.

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  annotations: {}
  labels: {}
  name: string
  namespace: string
spec: {}
```

### Node Placement

Kubernetes has the ability to schedule a pod to specific nodes based on [affinity and anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#node-affinity-beta-feature) rules.

[Node affinity](http://kubevirt.io/api-reference/master/definitions.html#_v1_nodeaffinity) is also possible with KubeVirt. To [constrain a virtual machine](hhttps://kubevirt.io/user-guide/operations/node_assignment/#affinity-and-anti-affinity) to run on a node define a matching expressions using node labels.

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - preference:
          matchExpressions:
            - key: string
              operator: string
              values:
                - string
        weight: 0
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: string
              operator: string
              values:
                - string
```

A virtual machine can also more easily be constrained by using [nodeSelector](https://kubevirt.io/user-guide/operations/node_assignment/#nodeselector) which is defined by node’s label and value. Here is an example

```yaml
nodeSelector:
  kubernetes.io/hostname: kn1.virtomation.com
```

### Clocks and Timers

Configures the [virtualize hardware](https://kubevirt.io/user-guide/virtual_machines/virtual_hardware/#clock) clock provided by [QEMU](https://www.qemu.org/docs/master/system/invocation.html#hxtool-9).

```yaml
domain:
  clock:
    timezone: string
    utc:
      offsetSeconds: 0
```

The [timer](https://kubevirt.io/user-guide/virtual_machines/virtual_hardware/#timers) defines the [type and policy attribute](https://libvirt.org/formatdomain.html#elementsTime) that determines what action is take when QEMU misses a deadline for injecting a tick to the guest.

```yaml
domain:
  clock:
    timer:
      hpet:
        present: true
        tickPolicy: string
      hyperv:
        present: true
      kvm:
        present: true
      pit:
        present: true
        tickPolicy: string
      rtc:
        present: true
        tickPolicy: string
        track: string
```

### CPU and Memory

The number of [CPU cores](https://kubevirt.io/user-guide/virtual_machines/virtual_hardware/#cpu) a virtual machine will be assigned. [.spec.domain.cpu.cores](http://kubevirt.io/api-reference/master/definitions.html#_v1_cpu) will not be used for scheduling use [.spec.domain.resources.requests.cpu](http://kubevirt.io/api-reference/master/definitions.html#_v1_resourcerequirements) instead.

```yaml
cpu:
  cores: 1
```

There are two supported [resource limits and requests](https://kubevirt.io/user-guide/virtual_machines/virtual_hardware/#resources-requests-and-limits): `cpu` and `memory`. A `.spec.domain.resources.requests.memory` should be defined to determine the allocation of memory provided to the virtual machine. These values will be used to in scheduling decisions.

```yaml
resources:
  limits: {}
  requests: {}
```

### Watchdog Devices

[.spec.domain.watchdog](http://kubevirt.io/api-reference/master/definitions.html#_v1_watchdog) automatically triggers an action via [Libvirt](https://libvirt.org/formatdomain.html#elementsWatchdog) and [QEMU](https://www.qemu.org/docs/master/system/invocation.html#hxtool-9) when the virtual machine operating system hangs or crashes.

```yaml
watchdog:
  i6300esb:
    action: string
  name: string
```

### Features

[.spec.domain.features](http://kubevirt.io/api-reference/master/definitions.html#_v1_features)
are hypervisor cpu or machine features that can be enabled.
After reviewing both Linux and Microsoft QEMU virtual machines managed by
[Libvirt](https://libvirt.org/formatdomain.html#elementsFeatures)
both acpi and
[apic](http://kubevirt.io/api-reference/master/definitions.html#_v1_featureapic)
should be enabled.
The [hyperv](http://kubevirt.io/api-reference/master/definitions.html#_v1_featurehyperv) features should be enabled only for Windows-based virtual machines. For additional information regarding features please visit the [virtual hardware configuration](https://kubevirt.io/user-guide/virtual_machines/virtual_hardware/#features) in the kubevirt user guide.

```yaml
features:
  acpi:
    enabled: true
  apic:
    enabled: true
    endOfInterrupt: true
  hyperv:
    relaxed:
      enabled: true
    reset:
      enabled: true
    runtime:
      enabled: true
    spinlocks:
      enabled: true
      spinlocks: 0
    synic:
      enabled: true
    synictimer:
      enabled: true
    vapic:
      enabled: true
    vendorid:
      enabled: true
      vendorid: string
    vpindex:
      enabled: true
```

### QEMU Machine Type

[.spec.domain.machine.type](https://kubevirt.io/user-guide/virtual_machines/virtual_hardware/#machine-type) is the emulated machine architecture provided by [QEMU](https://www.qemu.org/docs/master/system/invocation.html#hxtool-0).

```yaml
machine:
  type: string
```

Here is an example how to retrieve the supported QEMU machine types.

```sh
    $ qemu-system-x86_64 --machine help
    Supported machines are:
    ...output...
    pc                   Standard PC (i440FX + PIIX, 1996) (alias of pc-i440fx-2.10)
    pc-i440fx-2.10       Standard PC (i440FX + PIIX, 1996) (default)
    ...output...
    q35                  Standard PC (Q35 + ICH9, 2009) (alias of pc-q35-2.10)
    pc-q35-2.10          Standard PC (Q35 + ICH9, 2009)
```

### Disks and Volumes

[.spec.domain.devices.disks](https://kubevirt.io/api-reference/master/definitions.html#_v1_disk) configures a [QEMU](https://www.qemu.org/docs/master/system/invocation.html#hxtool-1) type of [disk](https://libvirt.org/formatdomain.html#elementsDisks) to the virtual machine and assigns a specific [volume and its type to that disk](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#containerdisk) via the `volumeName`.

```yaml
devices:
  disks:
    - cdrom:
        bus: string
        readonly: true
        tray: string
      disk:
        bus: string
        readonly: true
      floppy:
        readonly: true
        tray: string
      lun:
        bus: string
        readonly: true
      name: string
      volumeName: string
```

[cloudInitNoCloud](http://kubevirt.io/api-reference/master/definitions.html#_v1_cloudinitnocloudsource)
injects scripts and configuration into a virtual machine operating system.
There are three different parameters that can be used to provide the
cloud-init coniguration: `secretRef`, `userData` or `userDataBase64`.

See the user-guide for examples of how to use [.spec.volumes.cloudInitNoCloud](https://kubevirt.io/user-guide/virtual_machines/startup_scripts/#cloud-init-examples).

```yaml
volumes:
  - cloudInitNoCloud:
      secretRef:
        name: string
      userData: string
      userDataBase64: string
```

An [emptyDisk volume](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#emptydisk) creates an extra qcow2 disk that is created with the virtual machine. It will be removed if the `VirtualMachine` object is deleted.

```yaml
emptyDisk:
  capacity: string
```

[Ephemeral volume](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#ephemeral) creates a temporary local copy on write image storage that will be discarded when the `VirtualMachine` is removed.

```yaml
ephemeral:
  persistentVolumeClaim:
    claimName: string
    readOnly: true
name: string
```

[persistentVolumeClaim volume](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#persistentvolumeclaim) persists after the `VirtualMachine` is deleted.

```yaml
persistentVolumeClaim:
  claimName: string
  readOnly: true
```

[registryDisk volume](https://kubevirt.io/user-guide/virtual_machines/disks_and_volumes/#containerdisk) type uses a virtual machine disk that is stored in a container image registry.

```yaml
registryDisk:
  image: string
  imagePullSecret: string
```

### Virtual Machine Status

Once the `VirtualMachine` object has been created the [VirtualMachineStatus](http://kubevirt.io/api-reference/master/definitions.html#_v1_virtualmachinestatus) will be available. [VirtualMachineStatus](http://kubevirt.io/api-reference/master/definitions.html#_v1_virtualmachinestatus) can be used in automation tools such as Ansible to confirm running state, determine where a `VirtualMachine` is running via `nodeName` or the `ipAddress` of the virtual machine operating system.

    kubectl -o yaml get vm mongodb -n nodejs-ex

    # ...output...
    status:
      interfaces:
      - ipAddress: 10.244.2.7
      nodeName: kn2.virtomation.com
      phase: Running

Example using `--template` to retrieve the `.status.phase` of the `VirtualMachine`.

    kubectl get vm mongodb --template {% raw %}{{.status.phase}}{% endraw %} -n nodejs-ex
    Running

### Examples

- <https://kubevirt.io/user-guide/virtual_machines/virtual_machine_instances/#virtualmachineinstance-api>

## OfflineVirtualMachine

An OfflineVirtualMachine is an immortal object within KubeVirt. The VirtualMachine
described within the spec will be recreated with a start power operation, host issue
or simply a accidental deletion of the VirtualMachine object.
For a traditional virtual administrator this object might be appropriate for
most use-cases.

Just like `VirtualMachine` we can retrieve the `OfflineVirtualMachine` objects.

    $ kubectl get ovms -n nodejs-ex
    NAME      AGE
    mongodb   5d
    nodejs    5d

And display the object in yaml.

    $ kubectl -o yaml get ovms mongodb -n nodejs-ex
    apiVersion: kubevirt.io/v1alpha1
    kind: OfflineVirtualMachine
    metadata:
    ...output...

We continue by annotating `OfflineVirtualMachine` object.

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: OfflineVirtualMachine
metadata:
  annotations: {}
  labels: {}
  name: string
  namespace: string
spec:
```

### What is Running in OfflineVirtualMachine?

[.spec.running](https://kubevirt.io/api-reference/master/definitions.html#_v1_offlinevirtualmachinespec) controls whether the associated VirtualMachine object is created. In other words this changes the [power status](https://kubevirt.io/user-guide/virtual_machines/lifecycle/#stopping-a-virtual-machine) of the virtual machine.

      running: true

This will create a `VirtualMachine` object which will instantiate and power on a virtual machine.

    kubectl patch offlinevirtualmachine mongodb --type merge -p '{"spec":{"running":true }}' -n nodejs-ex

This will delete the `VirtualMachine` object which will power off the virtual machine.

    kubectl patch offlinevirtualmachine mongodb --type merge -p '{"spec":{"running":false }}' -n nodejs-ex

And if you would rather not have to remember the `kubectl patch` command above
the KubeVirt team has provided a cli tool `virtctl` that can start and stop
a guest.

```sh
./virtctl start mongodb -n nodejs-ex
./virtctl stop mongodb -n nodejs-ex
```

### Offline Virtual Machine Status

Once the `OfflineVirtualMachine` object has been created the [OfflineVirtualMachineStatus](http://kubevirt.io/api-reference/master/definitions.html#_v1_offlinevirtualmachinestatus) will be available. Like `VirtualMachineStatus` `OfflineVirtualMachineStatus` can be used for automation tools such as Ansible.

    kubectl -o yaml get ovms mongodb -n nodejs-ex

    # ...output...
    status:
      created: true
      ready: true

Example using `--template` to retrieve the `.status.conditions[0].type` of `OfflineVirtualMachine`.

    kubectl get ovm mongodb --template "{% raw %}{{.status.ready}}{% endraw %}" -n nodejs-ex
    true

## VirtualMachineReplicaSet

[VirtualMachineReplicaSet](https://kubevirt.io/user-guide/virtual_machines/replicaset/) is great when you want to run multiple identical virtual machines.

Just like the other top-level objects we can retrieve `VirtualMachineReplicaSet`.

    $ kubectl get vmrs -n nodejs-ex
    NAME      AGE
    replica   1m

With the `replicas` parameter set to `2` the command below displays the two `VirtualMachine` objects that were created.

    $ kubectl get vms -n nodejs-ex
    NAME           AGE
    replicanmgjl   7m
    replicarjhdz   7m

### Pause rollout

The [.spec.paused](http://kubevirt.io/api-reference/master/definitions.html#_v1_vmreplicasetspec) parameter if true pauses the deployment of the `VirtualMachineReplicaSet`.

      paused: true

### Replica quantity

The [.spec.replicas](https://kubevirt.io/user-guide/virtual_machines/replicaset/#using-virtualmachineinstancereplicaset) number of `VirtualMachine` objects that should be created.

      replicas: 0

The [selector](http://kubevirt.io/api-reference/master/definitions.html#_v1_labelselector) must be defined and match labels defined in the template. It is used by the controller to keep track of managed virtual machines.

```yaml
selector:
  matchExpressions:
    - key: string
      operator: string
      values:
        - string
  matchLabels: {}
```

### [Virtual Machine Template Spec](https://kubevirt.io/user-guide/virtual_machines/replicaset/#using-virtualmachineinstancereplicaset)

The `VMTemplateSpec` is the definition of a `VirtualMachine` objects that will be created.

In the `VirtualMachine` section the `.spec` `VirtualMachineSpec` describes the available parameters for that object.

```yaml
template:
  metadata:
    annotations: {}
    labels: {}
    name: string
    namespace: string
  spec: {}
```

### Replica Status

Like the other objects we already have discussed [VMReplicaSetStatus](http://kubevirt.io/api-reference/master/definitions.html#_v1_vmreplicasetstatus) is an important object to use for automation.

```yaml
status:
  readyReplicas: 0
  replicas: 0
```

Example using `--template` to retrieve the `.status.readyReplicas` and `.status.replicas` of `VirtualMachineReplicaSet`.

    $ kubectl get vmrs replica --template "{% raw %}{{.status.readyReplicas}}{% endraw %}" -n nodejs-ex
    2
    $ kubectl get vmrs replica --template "{% raw %}{{.status.replicas}}{% endraw %}" -n nodejs-ex
    2

### Examples

- <https://kubevirt.io/user-guide/virtual_machines/replicaset/#example>

## VirtualMachinePreset

This is used to define a `DomainSpec` that can be used for multiple virtual machines.

To configure a `DomainSpec` for multiple `VirtualMachine` objects the `selector` defines which `VirtualMachine` the `VirtualMachinePreset` should be applied to.

    $ kubectl get vmpreset -n nodejs-ex
    NAME       AGE
    m1.small   17s

### Domain Spec

See the `VirtualMachine` section above for annotated details of the `DomainSpec` object.

    spec:
      domain: {}

### Preset Selector

The [selector](https://kubevirt.io/user-guide/virtual_machines/presets/#virtualmachine-selector) is optional but if not defined will be applied to all `VirtualMachine` objects; which is probably not the intended purpose so I recommend always including a selector.

```yaml
selector:
  matchExpressions:
    - key: string
      operator: string
      values:
        - string
  matchLabels: {}
```

### Examples

- <https://kubevirt.io/user-guide/virtual_machines/presets/#examples>

We provided an annotated view into the KubeVirt objects - VirtualMachine, OfflineVirtualMachine, VirtualMachineReplicaSet and VirtualMachinePreset. Hopefully this will help a user of KubeVirt to understand the options and parameters that are currently available when creating a virtual machine on Kubernetes.
