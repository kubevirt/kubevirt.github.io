---
layout: post
author: tripledes
description: CDI DataVolumes
navbar_active: Blogs
pub-date: Oct 11
pub-year: 2018
category: news
comments: true
---

# CDI DataVolumes

Containerized Data Importer (or CDI for short), is a data import service for Kubernetes designed with KubeVirt in mind. Thanks to CDI, we can now enjoy the addition of DataVolumes, which greatly improve the workflow of managing KubeVirt and its storage.

## What it does

DataVolumes are an abstraction of the Kubernetes resource, PVC (Persistent Volume Claim) and it also leverages other CDI features to ease the process of importing data into a Kubernetes cluster.

DataVolumes can be defined by themselves or embedded within a VirtualMachine resource definition, the first method can be used to orchestrate events based on the DataVolume status phases while the second eases the process of providing storage for a VM.

## How does it work?

In this blog post, I'd like to focus on the second method, embedding the information within a VirtualMachine definition, which might seem like the most immediate benefit of this feature. Let's get started!

### Environment description

* **OpenShift**

   For testing DataVolumes, I've spawned a new OpenShift cluster, using dynamic provisioning for storage running OpenShift Cloud Storage (GlusterFS), so the Persistent Volumes (PVs for short) are created on-demand. Other than that, it's a regular OpenShift cluster, running with a single master (also used for infrastructure components) and two compute nodes.

* **CDI**

   We also need CDI, of course, CDI can be deployed either together with KubeVirt or independently, the instructions can be found in the project's [GitHub repo](https://github.com/kubevirt/containerized-data-importer).

* **KubeVirt**

  Last but not least, we'll need KubeVirt to run the VMs that will make use of the DataVolumes.


### Enabling DataVolumes feature

As of this writing, DataVolumes have to be enabled through a [feature gate](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/), for KubeVirt, this is achieved by creating the _kubevirt-config_ ConfigMap on the namespace where KubeVirt has been deployed, by default _kube-system_.

Let's create the ConfigMap with the following definition:


```yaml
---
apiVersion: v1
data:
  feature-gates: DataVolumes
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kube-system
```

```shell
$ oc create -f kubevirt-config-cm.yml
```

Alternatively, the following one-liner can also be used to achieve the same result:

```shell
$ oc create configmap kubevirt-config --from-literal feature-gates=DataVolumes -n kube-system
```

If the ConfigMap was already present on the system, just use `oc edit` to add the DataVolumes feature gate under the _data_ field like the YAML above.

If everything went as expected, we should see the following log lines on the _virt-controller_ pods:

```
level=info timestamp=2018-10-09T08:16:53.602400Z pos=application.go:173 component=virt-controller msg="DataVolume integration enabled"
```

> **NOTE**: It's worth noting the values in the ConfigMap are not dynamic, in the sense that _virt-controller_ and _virt-api_ will need to be _restarted_, scaling their deployments down and back up again, just remember to scale it up to the same number of replicas they previously had.


## Creating a VirtualMachine embedding a DataVolume

Now that the cluster is ready to use the feature, let's have a look at our VirtualMachine definition, which includes a DataVolume.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: testvm1
  name: testvm1
spec:
  dataVolumeTemplates:
    - metadata:
        name: centos7-dv
      spec:
        pvc:
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: 10Gi
        source:
          http:
            url: "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: testvm1
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
          - volumeName: test-datavolume
            name: disk0
            disk:
              bus: virtio
          - name: cloudinitdisk
            volumeName: cloudinitvolume
            cdrom:
              bus: virtio
        resources:
          requests:
            memory: 8Gi
      volumes:
      - dataVolume:
          name: centos7-dv
        name: test-datavolume
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            hostname: testvm1
            users:
              - name: kubevirt
                gecos: KubeVirt Project
                sudo: ALL=(ALL) NOPASSWD:ALL
                passwd: $6$JXbc3063IJir.e5h$ypMlYScNMlUtvQ8Il1ldZi/mat7wXTiRioGx6TQmJjTVMandKqr.jJfe99.QckyfH/JJ.OdvLb5/OrCa8ftLr.
                shell: /bin/bash
                home: /home/kubevirt
                lock_passwd: false
        name: cloudinitvolume
```

The new addition to a regular VirtualMachine definition is the _dataVolumeTemplates_ block, which will trigger the import of the CentOS-7 cloud image defined on the _url_ field, storing it on a PV, the resulting DataVolume will be named _centos7-dv_, being referenced on the _volumes_ section, it will serve as the boot disk (disk0) for our VirtualMachine.

Going ahead and applying the above manifest to our cluster results in the following set of events:

* The DataVolume is created, triggering the creation of a PVC and therefore, using the dynamic provisioning configured on the cluster, a PV is provisioned to satisfy the needs of the PVC.
* An importer pod is started, this pod is the one actually downloading the image defined in the _url_ field and storing it on the provisioned PV.
* Once the image has been downloaded and stored, the DataVolume status changes to _Succeeded_, from that point the virt launcher controller will go ahead and schedule the VirtualMachine.

Taking a look to the resources created after applying the VirtualMachine manifest, we can see the following:

```shell
$ oc get pods
NAME                          READY     STATUS      RESTARTS   AGE
importer-centos7-dv-t9zx2     0/1       Completed   0          11m
virt-launcher-testvm1-cpt8n   1/1       Running     0          8m
```

Let's look at the importer pod logs to understand what it did:

```shell
$ oc logs importer-centos7-dv-t9zx2
I1009 12:37:45.384032       1 importer.go:32] Starting importer
I1009 12:37:45.393461       1 importer.go:37] begin import process
I1009 12:37:45.393519       1 dataStream.go:235] copying "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2" to "/data/disk.img"...
I1009 12:37:45.393569       1 dataStream.go:112] IMPORTER_ACCESS_KEY_ID and/or IMPORTER_SECRET_KEY are empty
I1009 12:37:45.393606       1 dataStream.go:298] create the initial Reader based on the endpoint's "https" scheme
I1009 12:37:45.393665       1 dataStream.go:208] Attempting to get object "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2" via http client
I1009 12:37:45.762330       1 dataStream.go:314] constructReaders: checking compression and archive formats: /centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
I1009 12:37:45.841564       1 dataStream.go:323] found header of type "qcow2"
I1009 12:37:45.841618       1 dataStream.go:338] constructReaders: no headers found for file "/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
I1009 12:37:45.841635       1 dataStream.go:340] done processing "/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2" headers
I1009 12:37:45.841650       1 dataStream.go:138] NewDataStream: endpoint "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"'s computed byte size: 8589934592
I1009 12:37:45.841698       1 dataStream.go:566] Validating qcow2 file
I1009 12:37:46.848736       1 dataStream.go:572] Doing streaming qcow2 to raw conversion
I1009 12:40:07.546308       1 importer.go:43] import complete
```

So, following the events we see, it fetched the image from the defined _url_, validated its format and converted it to _raw_ for being used by _qemu_.

```shell
$ oc describe dv centos7-dv
Name:         centos7-dv
Namespace:    test-dv
Labels:       kubevirt.io/created-by=1916da5f-cbc0-11e8-b467-c81f666533c3
Annotations:  kubevirt.io/owned-by=virt-controller
API Version:  cdi.kubevirt.io/v1alpha1
Kind:         DataVolume
Metadata:
  Creation Timestamp:  2018-10-09T12:37:34Z
  Generation:          1
  Owner References:
    API Version:           kubevirt.io/v1alpha2
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  VirtualMachine
    Name:                  testvm1
    UID:                   1916da5f-cbc0-11e8-b467-c81f666533c3
  Resource Version:        2474310
  Self Link:               /apis/cdi.kubevirt.io/v1alpha1/namespaces/test-dv/datavolumes/centos7-dv
  UID:                     19186b29-cbc0-11e8-b467-c81f666533c3
Spec:
  Pvc:
    Access Modes:
      ReadWriteOnce
    Resources:
      Requests:
        Storage:  10Gi
  Source:
    Http:
      URL:  https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
Status:
  Phase:  Succeeded
Events:
  Type    Reason  Age                 From                   Message
  ----    ------  ----                ----                   -------
  Normal  Synced  29s (x13 over 14m)  datavolume-controller  DataVolume synced successfully
  Normal  Synced  18s                 datavolume-controller  DataVolume synced successfully
```

The DataVolume description matches what was defined under _dataVolumeTemplates_. Now, as we know it uses a PV/PVC underneath, let's have a look:

```shell
$ oc describe pvc centos7-dv
Name:          centos7-dv
Namespace:     test-dv
StorageClass:  glusterfs-storage
Status:        Bound
Volume:        pvc-191d27c6-cbc0-11e8-b467-c81f666533c3
Labels:        app=containerized-data-importer
               cdi-controller=centos7-dv
Annotations:   cdi.kubevirt.io/storage.import.endpoint=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
               cdi.kubevirt.io/storage.import.importPodName=importer-centos7-dv-t9zx2
               cdi.kubevirt.io/storage.pod.phase=Succeeded
               pv.kubernetes.io/bind-completed=yes
               pv.kubernetes.io/bound-by-controller=yes
               volume.beta.kubernetes.io/storage-provisioner=kubernetes.io/glusterfs
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      10Gi
Access Modes:  RWO
Events:
  Type    Reason                 Age   From                         Message
  ----    ------                 ----  ----                         -------
  Normal  ProvisioningSucceeded  18m   persistentvolume-controller  Successfully provisioned volume pvc-191d27c6-cbc0-11e8-b467-c81f666533c3 using kubernetes.io/glusterfs
```

It's important to pay attention to the annotations, these are monitored/set by CDI. CDI triggers an import when it detects the _cdi.kubevirt.io/storage.import.endpoint_, assigns a pod as the import task owner and updates the pod phase annotation.

At this point, everything is in place, the DataVolume has its underlying components, the image has been imported so now the VirtualMachine can start the VirtualMachineInstance based on its definition and using the CentOS7 image as boot disk, as users we can connect to its console as usual, for instance running the following command:

```shell
$ virtctl console testvm1
```

## Cleaning it up

Once we're happy with the results, it's time to clean up all these tests. The task is easy:

```shell
$ oc delete vm testvm1
```

Once the VM (and its associated VMI) are gone, all the underlying storage resources are removed, there is no trace of the PVC, PV or DataVolume.

```shell
$ oc get dv centos7-dv
$ oc get pvc centos7-dv
$ oc get pv pvc-191d27c6-cbc0-11e8-b467-c81f666533c3
```

All three commands returned _No resources found_.
