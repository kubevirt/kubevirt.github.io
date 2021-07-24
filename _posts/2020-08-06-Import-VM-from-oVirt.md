---
layout: post
author: Ondra Machacek
description: This blog post describes how to import virtual machine using vm-import-operator
navbar_active: Blogs
category: news
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
    "import",
    "oVirt",
  ]
comments: true
title: Import virtual machine from oVirt
pub-date: August 07
pub-year: 2020
---

## About vm-import-operator

Virtual machine import operator makes life easier for users who want to migrate their virtual machine workload from different infrastructures to KubeVirt. Currently the operator supports migration from oVirt only. The operator is configurable so user can define how the storage or network should be mapped. For the disk import vm import operator is using the [CDI](https://github.com/kubevirt/containerized-data-importer), so in order to have the vm import working you must have both KubeVirt and CDI installed.

### Import rules

Before the import process is initiated we run validation of the source VM, to be sure the KubeVirt will run the source VM smoothly. We have many [rules](https://github.com/kubevirt/vm-import-operator/blob/master/docs/rules.md) defined including storage, network and the VM. You will see all warning messages in the conditions field. For example:

```yaml
- lastHeartbeatTime: "2020-08-11T11:13:31Z"
  lastTransitionTime: "2020-08-11T11:13:31Z"
  message: 'VM specifies IO Threads: 1, VM has NUMA tune mode secified: interleave'
  reason: MappingRulesVerificationReportedWarnings
  status: "True"
  type: MappingRulesVerified
```

### Supported Guest Operating Systems

We support following guest operating systems:

* Red Hat Enterprise Linux 6
* Red Hat Enterprise Linux 7
* Red Hat Enterprise Linux 8
* Microsoft Windows 10
* Microsoft Windows Server 2012r2
* Microsoft Windows Server 2016
* Microsoft Windows Server 2019
* CentOS Linux 6
* CentOS Linux 7
* CentOS Linux 8
* Ubuntu 18.04
* Fedora
* openSUSE

## Setup vm-import-operator

Source code for virtual machine import operator is hosted on github under [KubeVirt](https://github.com/kubevirt) organization. You can very easily deploy it on your Kubernetes by running following commands:

```bash
kubectl apply -f https://github.com/kubevirt/vm-import-operator/releases/download/v0.1.0/namespace.yaml
kubectl apply -f https://github.com/kubevirt/vm-import-operator/releases/download/v0.1.0/operator.yaml
kubectl apply -f https://github.com/kubevirt/vm-import-operator/releases/download/v0.1.0/vmimportconfig_cr.yaml
```

By default the operator is deployed to `kubevirt-hyperconverged` namespace,
you can verify that the operator is deployed and running by running:

```bash
kubectl get deploy vm-import-controller -n kubevirt-hyperconverged
```

If you are using [HCO](https://github.com/kubevirt/hyperconverged-cluster-operator/), you don't have to install it manually,
because the HCO takes care of that.

## Importing virtual machine from oVirt

In order to import a virtual machine from oVirt user must obtain credentials for the oVirt environment. oVirt environment is usually accessed using username, password and http URL. Note that you must provide CA certificate of your oVirt environment. If you have those - create a secret out of them:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: ovirt-secret
type: Opaque
stringData:
  ovirt: |-
    apiUrl: https://engine-url/ovirt-engine/api
    username: admin@internal
    password: "secretpassword"
    caCert: |
      -----BEGIN CERTIFICATE-----
      MIIEMjCCAxqgAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwbDELMAkGA1UEBhMCVVMxJDAiBgNVBAoM
      ....
      fFyt91ClrUtTE707IFnYdQQUiZ4zI0q+6pmw6+xx8mH5k8Ad6D71pF718xCM1NiBx/Cusg==
      -----END CERTIFICATE-----
```

Another step to initiate the import is creating the mappings. The mappings has three categories - storage mapping, disk mapping and network mapping. For storage mapping user can define which oVirt storage domain will be mapped to which storage class. Disk mapping can override the storage mapping for specific disks. The network mappings map oVirt network to the kubernetes network. So here an simple example of mapping:

```yaml
apiVersion: v2v.kubevirt.io/v1alpha1
kind: ResourceMapping
metadata:
  name: myvm-mapping
  namespace: default
spec:
  ovirt:
    networkMappings:
      - source:
          name: ovirtmgmt/ovirtmgmt
        target:
          name: pod
        type: pod
    storageMappings:
      - source:
          name: mystoragedomain
        target:
          name: mystorageclass
```

The above mapping maps `ovirtmgmt/ovirtmgmt` which is in format of vNIC profile/network to the pod network and disks from `mystoragedomain` to `mystorageclass`. Once we have mapping and the secret, we can initiate the import by creating a VM import CR. You must provide the name of the mapping, secret, source VM and target VM name.

```yaml
apiVersion: v2v.kubevirt.io/v1alpha1
kind: VirtualMachineImport
metadata:
 name: myvm
 namespace: default
spec:
 providerCredentialsSecret:
   name: ovirt-secret
 resourceMapping:
   name: myvm-mapping
 targetVmName: testvm
 source:
   ovirt:
     vm:
       name: myvm
       cluster:
         name: mycluster
```

Note that it is also possible to use internal mappings, so the user can create the mappings inside the VM import CR, for example:

```yaml
apiVersion: v2v.kubevirt.io/v1alpha1
kind: VirtualMachineImport
metadata:
  name: myvm
  namespace: default
spec:
  providerCredentialsSecret:
    name: ovirt-secret
    namespace: default
  targetVmName: testvm
  source:
    ovirt:
      mappings:
        networkMappings:
          - source:
              name: ovirtmgmt/ovirtmgmt
            target:
              name: pod
            type: pod
        storageMappings:
          - source:
              name: mystoragedomain
            target:
              name: mystorageclass
      vm:
        name: myvm
        cluster:
          name: mycluster
```

Now let the operator do its work. You can explore the status by checking the status of the VM import CR

```yaml
...
status:
    conditions:
    - lastHeartbeatTime: "2020-08-05T13:09:22Z"
      lastTransitionTime: "2020-08-05T13:09:22Z"
      message: Validation completed successfully
      reason: ValidationCompleted
      status: "True"
      type: Valid
    - lastHeartbeatTime: "2020-08-05T13:09:22Z"
      lastTransitionTime: "2020-08-05T13:09:22Z"
      message: 'VM specifies IO Threads: 1, VM has NUMA tune mode secified: interleave'
      reason: MappingRulesVerificationReportedWarnings
      status: "True"
      type: MappingRulesVerified
    - lastHeartbeatTime: "2020-08-05T13:10:29Z"
      lastTransitionTime: "2020-08-05T13:09:22Z"
      message: Copying virtual machine disks
      reason: ProcessingCompleted
      status: "True"
      type: Processing
    - lastHeartbeatTime: "2020-08-05T13:10:29Z"
      lastTransitionTime: "2020-08-05T13:10:29Z"
      message: Virtual machine disks import done
      reason: VirtualMachineReady
      status: "True"
      type: Succeeded
    dataVolumes:
    - name: testvm-26097887-1f4d-4718-961f-f5b63a49c3f5
    targetVmName: testvm
```

The import process goes through different stages. The first stage is the validation where HCO checks for unsupported mappings.
The others are for processing and reporting to provide VM and disks ready status.

## Future

For future releases it is planned to support importing virtual machines from VMware, reporting Prometheus metrics and SR-IOV.
