---
layout: post
author: Lee Yarwood
description: An update on the `instancetype.kubevirt.io/v1beta1` API and CRDs within the `v1.0.0` release
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "instancetypes",
    "preferences",
    "VirtualMachine",
    "VirtualMachineInstancetype",
    "VirtualMachinePreference",
  ]
comments: true
title: Update on `instancetype.kubevirt.io/v1beta1`
pub-date: September 18 
pub-year: 2023
---

## What's new

### `instancetype.kubevirt.io/v1beta1`

https://github.com/kubevirt/kubevirt/issues/8235

A new version of the API and CRDs has landed in the `v1.0.0` release of KubeVirt.

Amongst other things new version introduces a single new instance type attribute:

* [`Spec.Memory.OvercommitPercent`](https://github.com/kubevirt/kubevirt/pull/9799)

As the name suggests this can be used to control memory overcommit as a percentage within an instance type.

```yaml
# Creating an instance type with an overcommitPercent of 15%
$ kubectl apply -f - <<EOF
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  name: overcommit
spec:
  cpu:
    guest: 1
  memory:
    guest: 128Mi
    overcommitPercent: 15
EOF

# Creating a simple VirtualMachine (that auto starts) using this VirtualMachineInstancetype
$ virtctl create vm --instancetype virtualmachineinstancetype/overcommit \
  --volume-containerdisk name:cirros,src:registry:5000/kubevirt/cirros-container-disk-demo:devel \
  --name cirros | kubectl apply -f -

# We can see that the VirtualMachineInstance is exposing `128Mi` of memory 
# to the guest but is only requesting `114085072` or ~`108Mi`
$ kubectl get vmi/cirros -o json | jq .spec.domain.memory,.spec.domain.resources
{
  "guest": "128Mi"
}
{
  "requests": {
    "memory": "114085072"
  }
}
```

The following hopefully self-explanatory preference attributes have also been introduced:

* [`Spec.PreferredSubdomain`](https://github.com/kubevirt/kubevirt/pull/9769)
* [`Spec.CPU.PreferredCPUFeatures`](https://github.com/kubevirt/kubevirt/pull/9765)
* [`Spec.Devices.PreferredInterfaceMasquerade`](https://github.com/kubevirt/kubevirt/pull/9761)
* [`Spec.PreferredTerminationGracePeriodSeconds`](https://github.com/kubevirt/kubevirt/pull/9744)

### Preference Resource Requirements

In addition to the above standalone preference attributes a new
[`Spec.Requirements`](https://github.com/kubevirt/kubevirt/pull/8780) attribute
and feature has been added. At present this can encapsulate the minimum
[CPU](http://kubevirt.io/api-reference/main/definitions.html#_v1beta1_cpupreferencerequirement)
and
[Memory](http://kubevirt.io/api-reference/main/definitions.html#_v1beta1_memorypreferencerequirement)
requirements for the preference that need to be provided by the underlying
`VirtualMachine` or associated
`VirtualMachine{ClusterInstancetype,Instancetype}`.

```yaml
# The following example shows the rejection of a VirtualMachine using an 
# instance type that doesn't provide enough resources to fulfil the resource
# requirements of a preference also referenced by the VirtualMachine:
$ kubectl apply -f - << EOF
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  name: csmall
spec:
  cpu:
    guest: 1
  memory:
    guest: 128Mi
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachinePreference
metadata:
  name: cirros
spec:
  devices:
    preferredDiskBus: virtio
  requirements:
    cpu:
      guest: 1
    memory:
      guest: 512Mi
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-cirros-csmall
spec:
  instancetype:
    kind: VirtualMachineInstancetype
    name: csmall
  preference:
    kind: VirtualMachinePreference
    name: cirros
  running: false
  template:
    spec:
      domain:
        devices: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: registry:5000/kubevirt/cirros-container-disk-demo:devel
        name: containerdisk
virtualmachineinstancetype.instancetype.kubevirt.io/csmall created
virtualmachinepreference.instancetype.kubevirt.io/cirros created
The request is invalid: spec.instancetype: failure checking preference requirements: insufficient Memory resources of 128Mi provided by instance type, preference requires 512Mi

# The following example shows the rejection of a VirtualMachine that
# doesn't provide enough resources itself to fulfil the resource
# requirements of a preference also referenced by the VirtualMachine.
#
# Note that here the preferredCPUTopology of the preference is used
# to determine the required guest visible vCPU topology of the VirtualMachine:
$ kubectl apply -f - << EOF
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachinePreference
metadata:
  name: cirros
spec:
  cpu:
    preferredCPUTopology: preferCores
  requirements:
    cpu:
      guest: 2
    memory:
      guest: 128Mi
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-cirros
spec:
  running: false
  preference:
    kind: VirtualMachinePreference
    name: cirros
  template:
    spec:
      domain:
        cpu:
          sockets: 2
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
        resources:
          requests:
            memory: 128Mi
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: registry:5000/kubevirt/cirros-container-disk-demo:devel
        name: containerdisk
EOF
The request is invalid: spec.template.spec.domain.cpu.cores: failure checking preference requirements: insufficient CPU resources of 0 vCPU provided by VirtualMachine, preference requires 2 vCPU provided as cores
```

### `instancetype.kubevirt.io/v1alpha{1,2} deprecation`

With the introduction of `instancetype.kubevirt.io/v1beta1` the older
`instancetype.kubevirt.io/v1alpha{1,2}` versions have been deprecated ahead of
removal in a future release (likely KubeVirt >= `v1.2.0`).

As with the recent deprecation of the
[`kubevirt.io/v1alpha3`](https://github.com/kubevirt/kubevirt/blob/main/docs/updates.md#v100-migration-to-new-storage-versions)
any users of these older `instancetype.kubevirt.io/v1alpha{1,2}` versions are
recommend to use the
[kube-storage-version-migrator](https://github.com/kubernetes-sigs/kube-storage-version-migrator)
tool to migrate the stored version of these objects to
`instancetype.kubevirt.io/v1beta1`. For operators of OKD/OCP environments this
tool is provided through the
[`cluster-kube-storage-version-migrator-operator`](https://github.com/openshift/cluster-kube-storage-version-migrator-operator).

Work to migrate `ControllerRevisions` containing older
`instancetype.kubevirt.io/v1alpha{1,2}` objects will be undertaken during the
`v1.1.0` release of KubeVirt and can be tracked below:

**Implement a conversion strategy for `instancetype.kubevirt.io/v1alpha{1,2}` objects stored in `ControllerRevisions` to `instancetype.kubevirt.io/v1beta1`**
https://github.com/kubevirt/kubevirt/issues/9909

### `virtctl image-upload`

https://github.com/kubevirt/kubevirt/pull/9753

The `virtctl image-upload` command has been extended with two new switches to
label the resulting `DataVolume` or `PVC` with a default instance type and
preference.

```yaml
# Upload a CirrOS image using a DataVolume and label it with a default instance type and preference
$ virtctl image-upload dv cirros --size=1Gi \
  --default-instancetype n1.medium \
  --default-preference cirros \
  --force-bind \
  --image-path=./cirros-0.6.1-x86_64-disk.img

# Check that the resulting DV and PVC have been labelled correctly
$ kubectl get dv/cirros -o json | jq .metadata.labels
{
  "instancetype.kubevirt.io/default-instancetype": "n1.medium",
  "instancetype.kubevirt.io/default-preference": "cirros"
}
$ kubectl get pvc/cirros -o json | jq .metadata.labels
{
  "app": "containerized-data-importer",
  "app.kubernetes.io/component": "storage",
  "app.kubernetes.io/managed-by": "cdi-controller",
  "instancetype.kubevirt.io/default-instancetype": "n1.medium",
  "instancetype.kubevirt.io/default-preference": "cirros"
}

# Use virtctl to create a VirtualMachine manifest using the inferFromVolume option for the instance type and preference
$ virtctl create vm --volume-pvc=name:cirros,src:cirros \
  --infer-instancetype \
  --infer-preference \
  --name cirros | yq .
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  creationTimestamp: null
  name: cirros
spec:
  instancetype:
    inferFromVolume: cirros
  preference:
    inferFromVolume: cirros
  runStrategy: Always
  template:
    metadata:
      creationTimestamp: null
    spec:
      domain:
        devices: {}
        resources: {}
      terminationGracePeriodSeconds: 180
      volumes:
        - name: cirros
          persistentVolumeClaim:
            claimName: cirros
status: {}

# Pass the manifest to kubectl and then check that the resulting instance type and prefrence matchers have been expanded correctly
$ virtctl create vm --volume-pvc=name:cirros,src:cirros \
  --infer-instancetype \
  --infer-preference \
  --name cirros | kubectl apply -f -
virtualmachine.kubevirt.io/cirros created

$ kubectl get vms/cirros -o json | jq '.spec.instancetype,.spec.preference'
{
  "kind": "virtualmachineclusterinstancetype",
  "name": "n1.medium",
  "revisionName": "cirros-n1.medium-1cbceb96-2771-497b-a4b7-7cad6742b385-1"
}
{
  "kind": "virtualmachineclusterpreference",
  "name": "cirros",
  "revisionName": "cirros-cirros-efc9aeac-05df-4034-aa82-45817ca0b6dc-1"
}
```

### common-instancetypes

#### `v0.3.0`

https://github.com/kubevirt/common-instancetypes/releases/tag/v0.3.0

##### New `O` Overcommitted instance type class

With the introduction of the `OvercommitPercent` attribute in
`instancetype.kubevirt.io/v1beta1` we have introduced a new `O` Overcommitted
instance type class. Initially this class sets `OvercommitPercent` to 50%:

```yaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineClusterInstancetype
metadata:
  annotations:
    instancetype.kubevirt.io/class: Overcommitted
    instancetype.kubevirt.io/description: |-
      The O Series is based on the N Series, with the only difference
      being that memory is overcommitted.

      *O* is the abbreviation for "Overcommitted".
    instancetype.kubevirt.io/version: "1"
  labels:
    instancetype.kubevirt.io/vendor: kubevirt.io
    instancetype.kubevirt.io/common-instancetypes-version: v0.3.0
  name: o1.medium
spec:
  cpu:
    guest: 1
  memory:
    guest: 4Gi
    overcommitPercent: 50

```

##### s/Neutral/Universal/g instance type class

The `N` Neutral instance type class has been renamed `U` for Universal after
several discussions about the future introduction of a new `N` Network focused
instance type set of classes. The latter is still being discussed but if you
have a specific use case you think we could cover in this family then please let
me know!

##### Deprecation of legacy instance types

```
$ kubectl get virtualmachineclusterinstancetypes \
    -linstancetype.kubevirt.io/deprecated=true
selecting podman as container runtime
NAME                     AGE
highperformance.large    3h53m
highperformance.medium   3h53m
highperformance.small    3h53m
server.large             3h53m
server.medium            3h53m
server.micro             3h53m
server.small             3h53m
server.tiny              3h53m
```

##### Resource labels

The following resource labels have been added to each hyperscale
instance type to aid users searching for a type with specific resources:

* `instancetype.kubevirt.io/cpu`
* `instancetype.kubevirt.io/memory`

Additionally the following optional boolean labels have also been added to
relevant instance types to help users looking for more specific
resources and features:

* `instancetype.kubevirt.io/dedicatedCPUPlacement`
* `instancetype.kubevirt.io/hugepages`
* `instancetype.kubevirt.io/isolateEmulatorThread`
* `instancetype.kubevirt.io/numa`
* `instancetype.kubevirt.io/gpus`

```
$ kubectl get virtualmachineclusterinstancetype \
    -linstancetype.kubevirt.io/hugepages=true
NAME          AGE
cx1.2xlarge   113s
cx1.4xlarge   113s
cx1.8xlarge   113s
cx1.large     113s
cx1.medium    113s
cx1.xlarge    113s
m1.2xlarge    113s
m1.4xlarge    113s
m1.8xlarge    113s
m1.large      113s
m1.xlarge     113s

$ kubectl get virtualmachineclusterinstancetype \
    -linstancetype.kubevirt.io/cpu=4
NAME         AGE
cx1.xlarge   3m8s
gn1.xlarge   3m8s
m1.xlarge    3m8s
n1.xlarge    3m8s

$ kubectl get virtualmachineclusterinstancetype \
    -linstancetype.kubevirt.io/cpu=4,instancetype.kubevirt.io/hugepages=true
NAME         AGE
cx1.xlarge   5m47s
m1.xlarge    5m47s
```

##### Version label

All released resources are now labelled with a
`instancetype.kubevirt.io/common-instancetypes-version` label denoting the
release the resource came from.

```
$ curl -Ls https://github.com/kubevirt/common-instancetypes/releases/download/v0.3.0/common-clusterinstancetypes-bundle-v0.3.0.yaml | yq '.metadata.labels["instancetype.kubevirt.io/common-instancetypes-version"]' | sort | uniq
---
v0.3.0
```

## What’s coming next

https://github.com/kubevirt/kubevirt/issues?q=is%3Aissue+is%3Aopen+label%3Aarea%2Finstancetype 

### `instancetype.kubevirt.io/v1`

https://github.com/kubevirt/kubevirt/issues/9898

With `instancetype.kubevirt.io/v1beta1` out the door it's time to start planning
`v1`. At the moment there isn't a need for a `v1beta2` but I'm always open to
introducing that first if the need arises.

### Deployment of `common-instancetypes` from `virt-operator`

https://github.com/kubevirt/kubevirt/issues/9899

This has been long talked about and raised a few times in my blog post but the
time has definitely come to look at this seriously with KubeVirt `v1.1.0` *and*
`instancetype.kubevirt.io/v1`.

A formal community design proposal ([or an enhancement if I get my
way](https://github.com/kubevirt/community/issues/223)) will be written up in
the coming weeks setting out how we might be able to achieve this.

### Migration of existing ControllerRevisions to the latest `instancetype.kubevirt.io` version

https://github.com/kubevirt/kubevirt/issues/9909

Again long talked about but with a possible move to
`instancetype.kubevirt.io/v1` I really want to enable the removal of older
versions such as `v1alpha{1,2}` and `v1beta1`.

### Reducing the number of created ControllerRevisions

https://github.com/kubevirt/kubevirt/issues/8591

The final item I want to complete in the next release is again a long talked
about short coming in the original implementation of the API. With the growing
use of the API and CRDs I do want to address this in `v1.1.0`.
