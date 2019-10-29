---
layout: post
author: Pedro Ibáñez Requena
description: Persistent storage of your Virtual Machines in KubeVirt with Rook
navbar_active: Blogs
category: news
comments: true
title: Persistent storage of your Virtual Machines in KubeVirt with Rook
pub-date: October
pub-year: 2019
---

![KubeVirt](/images/kubevirt-stacked-color_250.png "KubeVirt")
![Rook](/images/rook-stacked-color_250.png "Rook")
![Ceph](/images/Ceph_Logo_Standard_RGB_120411_fa_250.png "Ceph")

## Pre-requisites
> In computer science, persistence refers to the characteristic of state that outlives the process
that created it. This is achieved in practice by storing the state as data in computer data storage.
Programs have to transfer data to and from storage devices and have to provide mappings from the
native programming-language data structures to the storage device data structures. [Wikipedia](https://en.wikipedia.org/wiki/Persistence_(computer_science))

In this post, we are going to show how to set up a persistence system to store VM images with the help of [Ceph](https://ceph.io) and the automation of [Rook](https://rook.io).

Some prerequisites have to be met:
- An existent Kubernetes cluster with 3 masters and 1 worker (min) is already set up, it's not mandatory to have that setup but for showing an example of a HA Ceph installation.
- Each Kubernetes node has an extra empty disk connected (has to be blank with no filesystem).
- KubeVirt is already installed and running.

In this example the following systems names and IP addresses are used:

| System      | Purpose  |  IP | 
| ------------- | ---------- | ------------- |
| kv-master-00     | Kubernetes Master node 00 | 192.168.122.6     |
| kv-master-01     | Kubernetes Master node 01 | 192.168.122.106     |
| kv-master-02     | Kubernetes Master node 02 | 192.168.122.206     |
| kv-worker-00     | Kubernetes Worker node 00 | 192.168.122.222     |


To have this system able to import Virtual Machines, the KubeVirt CDI has to be configured.

> Containerized-Data-Importer (CDI) is a persistent storage management add-on for Kubernetes. Its primary goal is to provide a declarative way to build Virtual Machine Disks on PVCs for Kubevirt VMs.

> CDI works with standard core Kubernetes resources and is storage device-agnostic, while its primary focus is to build disk images for Kubevirt, it's also useful outside of a Kubevirt context to use for initializing your Kubernetes Volumes with data.

In the case your cluster doesn't have CDI, the following commands take care of the CDI operator and the cr set up:
```sh
[root@kv-master-00 ~]# export VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\+\.[0-9]*\.[0-9]*")

[root@kv-master-00 ~]# kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
namespace/cdi created
customresourcedefinition.apiextensions.k8s.io/cdis.cdi.kubevirt.io created
configmap/cdi-operator-leader-election-helper created
serviceaccount/cdi-operator created
clusterrole.rbac.authorization.k8s.io/cdi-operator-cluster created
clusterrolebinding.rbac.authorization.k8s.io/cdi-operator created
deployment.apps/cdi-operator created
containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml

[root@kv-master-00 ~]# kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
cdi.cdi.kubevirt.io/cdi created

```

The nodes of the cluster have to be time synchronised (note that this should have been done for you by chronyd but it can't harm to do it again):

```
[root@kv-master-00 ~]# for i in $(echo 6 106 206 222); do ssh -oStrictHostKeyChecking=no \
    root@192.168.122.$i sudo chronyc -a makestep; done

Warning: Permanently added '192.168.122.6' (ECDSA) to the list of known hosts.
200 OK
Warning: Permanently added '192.168.122.106' (ECDSA) to the list of known hosts.
200 OK
Warning: Permanently added '192.168.122.206' (ECDSA) to the list of known hosts.
200 OK
Warning: Permanently added '192.168.122.222' (ECDSA) to the list of known hosts.
200 OK
```

> NOTE: This step could also be done with ansible (one line or rhel-system-roles.noarch).


## Installing Rook in Kubernetes to handle the Ceph cluster
Next, the latest upstream release of Rook has to be cloned:
```
[root@kv-master-00 ~]# git clone https://github.com/rook/rook
Cloning into 'rook'...
remote: Enumerating objects: 1, done.
remote: Counting objects: 100% (1/1), done.
remote: Total 37745 (delta 0), reused 0 (delta 0), pack-reused 37744
Receiving objects: 100% (37745/37745), 13.02 MiB | 1.54 MiB/s, done.
Resolving deltas: 100% (25309/25309), done.
```
Now change directory to the location of the Kubernetes examples where the respective resource definitions can be found:
```
[root@kv-master-00 ~]# cd rook/cluster/examples/kubernetes/ceph
```

The Rook common resources that make up Rook have to be created:

```sh
[root@kv-master-00 ~]# kubectl create -f common.yaml
(output removed)
```

Next, create the Kubernetes Rook operator:
```sh
[root@kv-master-00 ~]# kubectl create -f operator.yaml
deployment.apps/rook-ceph-operator created
```

To check the progress of the operator pod, and the discovery pods starting up to the commands below can be executed. The discovery pods are responsible for investigating the available resources (e.g. disks that can make up OSD's) across all available Nodes:

```sh
[root@kv-master-00 ~]# watch kubectl get pods -n rook-ceph
NAME                                 READY   STATUS             RESTARTS   AGE
rook-ceph-operator-fdfbcc5c5-qs7x8   1/1     Running            1          3m14s
rook-discover-7v65m                  1/1     Running            2          2m19s
rook-discover-cjfdz                  1/1     Running            0          2m19s
rook-discover-f8k4s                  0/1     ImagePullBackOff   0          2m19s
rook-discover-x22hh                  1/1     Running            0          2m19s

NAME                                     READY   STATUS    RESTARTS   AGE
pod/rook-ceph-operator-fdfbcc5c5-qs7x8   1/1     Running   1          4m21s
pod/rook-discover-7v65m                  1/1     Running   2          3m26s
pod/rook-discover-cjfdz                  1/1     Running   0          3m26s
pod/rook-discover-f8k4s                  1/1     Running   0          3m26s
pod/rook-discover-x22hh                  1/1     Running   0          3m26s
```

Next, to set the Ceph cluster configuration inside of the Rook operator:

```sh
[root@kv-master-00 ~]# kubectl create -f cluster.yaml
cephcluster.ceph.rook.io/rook-ceph created
```

One of the key elements of the default cluster configuration is to configure the Ceph cluster to use all nodes and use all devices, i.e. run Rook/Ceph on every system and consume any free disks that it finds; this makes configuring Rook a lot more simple:

```sh
[root@kv-master-00 ~]# grep useAll cluster.yml
    useAllNodes: true
    useAllDevices: true
    # Individual nodes and their config can be specified as well, but 'useAllNodes' above must be set to false. Then, only the named
```

The progress can be checked now, check the pods in the `rook-ceph` namespace:

```sh
[root@kv-master-00 ~]# watch kubectl -n rook-ceph get pods
NAME                                            READY   STATUS              RESTARTS   AGE
csi-cephfsplugin-2kqbd                          3/3     Running             0          36s
csi-cephfsplugin-hjnf9                          3/3     Running             0          36s
csi-cephfsplugin-provisioner-75c965db4f-tbgfn   4/4     Running             0          36s
csi-cephfsplugin-provisioner-75c965db4f-vgcwv   4/4     Running             0          36s
csi-cephfsplugin-svcjk                          3/3     Running             0          36s
csi-cephfsplugin-tv6rs                          3/3     Running             0          36s
csi-rbdplugin-dsdwk                             3/3     Running             0          37s
csi-rbdplugin-provisioner-69c9869dc9-bwjv4      5/5     Running             0          37s
csi-rbdplugin-provisioner-69c9869dc9-vzzp9      5/5     Running             0          37s
csi-rbdplugin-vzhzz                             3/3     Running             0          37s
csi-rbdplugin-w5n6x                             3/3     Running             0          37s
csi-rbdplugin-zxjcc                             3/3     Running             0          37s
rook-ceph-mon-a-canary-84c7fc67ff-pf7t5         1/1     Running             0          14s
rook-ceph-mon-b-canary-5f7c7cfbf4-8dvcp         1/1     Running             0          8s
rook-ceph-mon-c-canary-7779478497-7x25x         0/1     ContainerCreating   0          3s
rook-ceph-operator-fdfbcc5c5-qs7x8              1/1     Running             1          9m30s
rook-discover-7v65m                             1/1     Running             2          8m35s
rook-discover-cjfdz                             1/1     Running             0          8m35s
rook-discover-f8k4s                             1/1     Running             0          8m35s
rook-discover-x22hh                             1/1     Running             0          8m35s

```
Wait until the Ceph monitor pods are created. Next up, the toolbox pod has to be created; this is useful to verify the status/health of the cluster, getting/setting authentication, and querying the Ceph cluster using standard Ceph tools:

```sh
[root@kv-master-00 ~]# kubectl create -f toolbox.yaml
deployment.apps/rook-ceph-tools created
```

To check how well this is progressing:

```sh
[root@kv-master-00 ~]# kubectl -n rook-ceph get pods | grep tool
rook-ceph-tools-856c5bc6b4-s47qm                       1/1     Running   0          31s
```

Before proceeding with the pool and the storage class the Ceph cluster status can be checked already:
```sh
[root@kv-master-00 ~]# toolbox=$(kubectl -n rook-ceph get pods -o custom-columns=NAME:.metadata.name --no-headers | grep tools)

[root@kv-master-00 ~]# kubectl -n rook-ceph exec -it $toolbox sh
sh-4.2# ceph status
  cluster:
    id:     5a0bbe74-ce42-4f49-813d-7c434af65aad
    health: HEALTH_WARN
            clock skew detected on mon.c
 
  services:
    mon: 3 daemons, quorum a,b,c (age 3m)
    mgr: a(active, since 2m)
    osd: 4 osds: 4 up (since 105s), 4 in (since 105s)
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   4.0 GiB used, 72 GiB / 76 GiB avail
    pgs:
```
> NOTE: In this example, the health value is HEALTH_WARN because there is a clock skew between the monitor in node c and the rest of the cluster. If this is your case, go to the troubleshooting point at the end of the blogpost to find out how to solve this issue and get a HEALTH_OK.

Next, some other resources need to be created. First, the block pool that defines the name (and specification) of the RBD pool that will be used for creating persistent volumes, in this case, is called `replicapool`:

## Configuring the CephBlockPool and the Kubernetes StorageClass for using Ceph hosting the Virtual Machines
The `cephblockpool.yml` is based in the `pool.yml`, you can check that file in the same directory to learn about the details of each parameter:

```sh
[root@kv-master-00 ~]# cat pool.yml
```
```yaml
#################################################################################################################
# Create a Ceph pool with settings for replication in production environments. A minimum of 3 OSDs on
# different hosts are required in this example.
#  kubectl create -f pool.yaml
#################################################################################################################

apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  # The failure domain will spread the replicas of the data across different failure zones
  failureDomain: host
  # For a pool based on raw copies, specify the number of copies. A size of 1 indicates no redundancy.
  replicated:
    size: 3
  # A key/value list of annotations
  annotations:
  #  key: value
```

The following file is the one that has to be created to define the CephBlockPool:
```sh
[root@kv-master-00 ~]# vim cephblockpool.yml
```
```yaml
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 2
```
```sh
[root@kv-master-00 ~]# kubectl create -f cephblockpool.yml
cephblockpool.ceph.rook.io/replicapool created

[root@kv-master-00 ~]# kubectl get cephblockpool -n rook-ceph
NAME          AGE
replicapool   19s
```

Now is time to create the Kubernetes storage class that would be used to create the volumes later:

```sh
[root@kv-master-00 ~]# vim storageclass.yml
```
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: rook-ceph-block
# Change "rook-ceph" provisioner prefix to match the operator namespace if needed
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
    # clusterID is the namespace where the rook cluster is running
    clusterID: rook-ceph
    # Ceph pool into which the RBD image shall be created
    pool: replicapool

    # RBD image format. Defaults to "2".
    imageFormat: "2"

    # RBD image features. Available for imageFormat: "2". CSI RBD currently supports only `layering` feature.
    imageFeatures: layering

    # The secrets contain Ceph admin credentials.
    csi.storage.k8s.io/provisioner-secret-name: rook-ceph-csi
    csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
    csi.storage.k8s.io/node-stage-secret-name: rook-ceph-csi
    csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph

    # Specify the filesystem type of the volume. If not specified, csi-provisioner
    # will set default as `ext4`.
    csi.storage.k8s.io/fstype: xfs

# Delete the rbd volume when a PVC is deleted
reclaimPolicy: Delete
```
```sh
[root@kv-master-00 ~]# kubectl create -f storageclass.yml
storageclass.storage.k8s.io/rook-ceph-block created

[root@kv-master-00 ~]# kubectl get storageclass
NAME              PROVISIONER                  AGE
rook-ceph-block   rook-ceph.rbd.csi.ceph.com   61s
```
> NOTE: Special attention to the pool name, it has to be the same as configured in the CephBlockPool.

Now simply wait for the Ceph OSD's to finish provisioning and we'll be done with our Ceph deployment:

```sh
[root@kv-master-00 ~]# watch  "kubectl -n rook-ceph get pods | grep rook-ceph-osd-prepare"
rook-ceph-osd-prepare-kv-master-00.kubevirt-io-4npmf   0/1     Completed   0          20m
rook-ceph-osd-prepare-kv-master-01.kubevirt-io-69smd   0/1     Completed   0          20m
rook-ceph-osd-prepare-kv-master-02.kubevirt-io-zm7c2   0/1     Completed   0          20m
rook-ceph-osd-prepare-kv-worker-00.kubevirt-io-5qmjg   0/1     Completed   0          20m

```
>NOTE: This process may take a few minutes as it has to zap the disks, deploy a BlueStore configuration on them, and start the OSD service pods across our nodes.

Now, the cluster deployment can be validated:

```sh
[root@kv-master-00 ~]# kubectl -n rook-ceph exec -it $toolbox sh
sh-4.2# ceph -s
  cluster:
    id:     5a0bbe74-ce42-4f49-813d-7c434af65aad
    health: HEALTH_WARN
            too few PGs per OSD (4 < min 30)
 
  services:
    mon: 3 daemons, quorum a,b,c (age 12m)
    mgr: a(active, since 21m)
    osd: 4 osds: 4 up (since 20m), 4 in (since 20m)
 
  data:
    pools:   1 pools, 8 pgs
    objects: 0 objects, 0 B
    usage:   4.0 GiB used, 72 GiB / 76 GiB avail
    pgs:     8 active+clean
```
Oh Wait! the health value is again HEALTH_WARN, no problem, it is because there are too few PGs per OSD, in this case 4, for a minimum value of 30. Let's fix it changing that value to 256:

```sh
[root@kv-master-00 ~]# kubectl -n rook-ceph exec -it $toolbox sh
sh-4.2# ceph osd pool set replicapool pg_num 256
set pool 1 pg_num to 256

sh-4.2# ceph -s
  cluster:
    id:     5a0bbe74-ce42-4f49-813d-7c434af65aad
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 18m)
    mgr: a(active, since 27m)
    osd: 4 osds: 4 up (since 26m), 4 in (since 26m)
 
  data:
    pools:   1 pools, 256 pgs
    objects: 0 objects, 0 B
    usage:   4.0 GiB used, 72 GiB / 76 GiB avail
    pgs:     12.109% pgs unknown
             0.391% pgs not active
             224 active+clean
             31  unknown
             1   peering

```
In a moment Ceph will end peering and the status of the pgs would be `active+clean`:
```sh
sh-4.2# ceph -s
  cluster:
    id:     5a0bbe74-ce42-4f49-813d-7c434af65aad
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 21m)
    mgr: a(active, since 29m)
    osd: 4 osds: 4 up (since 28m), 4 in (since 28m)
 
  data:
    pools:   1 pools, 256 pgs
    objects: 0 objects, 0 B
    usage:   4.0 GiB used, 72 GiB / 76 GiB avail
    pgs:     256 active+clean
```

Some additional checks on the Ceph cluster can be made:
```sh
sh-4.2# ceph osd tree
ID CLASS WEIGHT  TYPE NAME                         STATUS REWEIGHT PRI-AFF 
-1       0.07434 root default                                              
-9       0.01859     host kv-master-00-kubevirt-io                         
 3   hdd 0.01859         osd.3                         up  1.00000 1.00000 
-7       0.01859     host kv-master-01-kubevirt-io                         
 2   hdd 0.01859         osd.2                         up  1.00000 1.00000 
-3       0.01859     host kv-master-02-kubevirt-io                         
 0   hdd 0.01859         osd.0                         up  1.00000 1.00000 
-5       0.01859     host kv-worker-00-kubevirt-io                         
 1   hdd 0.01859         osd.1                         up  1.00000 1.00000

sh-4.2# ceph osd status
+----+--------------------------+-------+-------+--------+---------+--------+---------+-----------+
| id |           host           |  used | avail | wr ops | wr data | rd ops | rd data |   state   |
+----+--------------------------+-------+-------+--------+---------+--------+---------+-----------+
| 0  | kv-master-02.kubevirt-io | 1026M | 17.9G |    0   |     0   |    0   |     0   | exists,up |
| 1  | kv-worker-00.kubevirt-io | 1026M | 17.9G |    0   |     0   |    0   |     0   | exists,up |
| 2  | kv-master-01.kubevirt-io | 1026M | 17.9G |    0   |     0   |    0   |     0   | exists,up |
| 3  | kv-master-00.kubevirt-io | 1026M | 17.9G |    0   |     0   |    0   |     0   | exists,up |
+----+--------------------------+-------+-------+--------+---------+--------+---------+-----------+

```

That should match the available block devices in the nodes, let's check it in the `kv-master-00` node:
```sh
[root@kv-master-00 ~]# lsblk 
NAME                                                                                                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sr0                                                                                                   11:0    1  512K  0 rom  
vda                                                                                                  253:0    0   50G  0 disk 
└─vda1                                                                                               253:1    0   50G  0 part /
vdb                                                                                                  253:16   0   20G  0 disk 
└─ceph--09112f92--11cd--4284--b763--447065cc169c-osd--data--0102789c--852c--4696--96ce--54c2ad3a848b 252:0    0   19G  0 lvm
```

It can also be shown that these pods are running across the correct nodes, see the 'NODE' column below:

```sh
[root@kv-master-00 ~]# kubectl get pods -n rook-ceph -o wide | egrep '(NAME|osd)'
NAME                                                   READY   STATUS      RESTARTS   AGE   IP                NODE                       NOMINATED NODE   READINESS GATES
rook-ceph-osd-0-8689c68c78-rgdbj                       1/1     Running     0          31m   10.244.2.9        kv-master-02.kubevirt-io   <none>           <none>
rook-ceph-osd-1-574cb85d9d-vs2jc                       1/1     Running     0          31m   10.244.3.18       kv-worker-00.kubevirt-io   <none>           <none>
rook-ceph-osd-2-65b54c458f-zkk6v                       1/1     Running     0          31m   10.244.1.10       kv-master-01.kubevirt-io   <none>           <none>
rook-ceph-osd-3-5fd97cd4c9-2xd6c                       1/1     Running     0          30m   10.244.0.10       kv-master-00.kubevirt-io   <none>           <none>
rook-ceph-osd-prepare-kv-master-00.kubevirt-io-4npmf   0/1     Completed   0          31m   10.244.0.9        kv-master-00.kubevirt-io   <none>           <none>
rook-ceph-osd-prepare-kv-master-01.kubevirt-io-69smd   0/1     Completed   0          31m   10.244.1.9        kv-master-01.kubevirt-io   <none>           <none>
rook-ceph-osd-prepare-kv-master-02.kubevirt-io-zm7c2   0/1     Completed   0          31m   10.244.2.8        kv-master-02.kubevirt-io   <none>           <none>
rook-ceph-osd-prepare-kv-worker-00.kubevirt-io-5qmjg   0/1     Completed   0          31m   10.244.3.17       kv-worker-00.kubevirt-io   <none>           <none>
```

All good!

For validating the storage provisioning through the new Ceph cluster managed by the Rook operator, a persistent volume claim (PVC) can be created:
```sh
[root@kv-master-00 ~]# vim pvc.yml
```
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-claim
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```
```sh
[root@kv-master-00 ceph]# kubectl create -f pvc.yml 
persistentvolumeclaim/pv-claim created
```
> NOTE: Ensure that the `storageClassName` contains the name of the storage class you have created, in this case, `rook-ceph-block`

For checking that it has been bound, list the PVCs and look for the ones in the `rook-ceph-block` storageclass:
```sh
[root@kv-master-00 ~]# kubectl get pvc
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
pv-claim   Bound    pvc-62a9738a-e027-4a68-9ecf-16278711ff64   1Gi        RWO            rook-ceph-block   63s
```

>NOTE: If the volume is still in a 'Pending' state, likely, that one of the pods haven't come up correctly or one of the steps above has been missed. To check it, the command 'kubectl get pods -n rook-ceph' can be executed for viewing the running/failed pods.

Before proceeding let's clean up the temporary PVC:
```sh
[root@kv-master-00 ~]# kubectl delete pvc pv-claim
persistentvolumeclaim "pv-claim" deleted
```

## Creating a Virtual Machine in KubeVirt backed by Ceph
Once the Ceph cluster is up and running, the first Virtual Machine can be created, to do so, a YML example file is being downloaded and modified:
```sh
[root@kv-master-00 ~]# wget https://raw.githubusercontent.com/kubevirt/containerized-data-importer/master/manifests/example/vm-dv.yaml
[root@kv-master-00 ~]# sed -i 's/hdd/rook-ceph-block/' vm-dv.yaml
[root@kv-master-00 ~]# sed -i 's/fedora/centos/' vm-dv.yaml
[root@kv-master-00 ~]# sed -i 's@https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img@http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2@' vm-dv.yaml
[root@kv-master-00 ~]# sed -i 's/storage: 100M/storage: 9G/' vm-dv.yaml
[root@kv-master-00 ~]# sed -i 's/memory: 64M/memory: 1G/' vm-dv.yaml
```

The modified YAML could be run already like this but a user won't be able to log in as we don't know the password used in that image. `cloud-init` can be used to change the password of the default user of that image `centos` and grant us access, two parts have to be added:
- Add a second disk after the `datavolumevolume` (already existing), in this example is called `cloudint`:
```sh
[root@kv-master-00 ~]# vim vm-dv.yaml
```
```yaml
...
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-datavolume
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumevolume
          - disk:
              bus: virtio
            name: cloudinit
...
``` 
- Afterwards, add the volume at the end of the file, after the volume already defined as `datavolumevolume`, in this example it's also called `cloudinit`:
```sh
[root@kv-master-00 ~]# vim vm-dv.yaml
```
```yaml
...
      volumes:
      - dataVolume:
          name: centos-dv
        name: datavolumevolume
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            password: changeme
            chpasswd: { expire: False }
        name: cloudinit
```
The password value is up to you (`changeme` in this example), you can set it as you like.

Once the YAML file is prepared the Virtual Machine can be created and started:
```
[root@kv-master-00 ~]# kubectl create -f vm-dv.yaml
virtualmachine.kubevirt.io/vm-centos-datavolume created

[root@kv-master-00 ~]# kubectl get vm
NAME                   AGE   RUNNING   VOLUME
vm-centos-datavolume              62m   false
```

Let's wait a little bit until the importer pod finishes, you can check it with:
```sh
[root@kv-master-00 ~]# kubectl get pods 
NAME                       READY   STATUS              RESTARTS   AGE
importer-centos-dv-8v6l5   0/1     ContainerCreating   0          12s
```

Once that pods ends, the Virtual Machine can be started (in this case the virt parameter can be used because of the [krew plugin system](https://kubevirt.io/user-guide/docs/latest/administration/intro.html#client-side-virtctl-deployment):
```sh
[root@kv-master-00 tmp]# kubectl virt start vm-centos-datavolume
VM vm-centos-datavolume was scheduled to start

[root@kv-master-00 ~]# kubectl get vmi
NAME                   AGE    PHASE     IP            NODENAME
vm-centos-datavolume   2m4s   Running   10.244.3.20   kv-worker-00.kubevirt-io

[root@kv-master-00 ~]# kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
centos-dv   Bound    pvc-5604eb4a-21dd-4dca-8bb7-fbacb0791402   9Gi        RWO            rook-ceph-block   7m34s
```

Awesome! the Virtual Machine is running in a pod through KubeVirt and it's backed up with Ceph under the management of Rook. Now it's the time for grabbing a coffee to allow cloud-init to do its job. A little while later let's connect to that VM console:
```
[root@kv-master-00 ~]# kubectl virt console vm-centos-datavolume
Successfully connected to vm-centos-datavolume console. The escape sequence is ^]

CentOS Linux 7 (Core)
Kernel 3.10.0-957.27.2.el7.x86_64 on an x86_64


vm-centos-datavolume login: centos
Password:
[centos@vm-centos-datavolume ~]$ 
```

And there it is, our Kubernetes cluster provided with virtualization capabilities thanks to KubeVirt and backed up with a strong Ceph cluster under the management of Rook.

## Troubleshooting
It can happen that once the Ceph cluster is created, the hosts are not properly time-synchronized, in that case, the Ceph configuration can be modified to allow a bigger time difference between the nodes, in this case, the variable `mon clock drift allowed` is changed to 0.5 seconds, the steps to do so are the following:
- Connect to the toolbox pod to check the cluster status
- Modify the configMap with the Ceph cluster configuration
- Verify the changes
- Remove the mon pods to apply the new configuration

```sh
[root@kv-master-00 ~]# kubectl -n rook-ceph exec -it $toolbox sh
sh-4.2# ceph status
  cluster:
    id:     5a0bbe74-ce42-4f49-813d-7c434af65aad
    health: HEALTH_WARN
            clock skew detected on mon.c
 
  services:
    mon: 3 daemons, quorum a,b,c (age 3m)
    mgr: a(active, since 2m)
    osd: 4 osds: 4 up (since 105s), 4 in (since 105s)
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   4.0 GiB used, 72 GiB / 76 GiB avail
    pgs:
  
[root@kv-master-00 ~]# kubectl -n rook-ceph edit ConfigMap rook-config-override -o yaml
config: |                            
    [global]
    mon clock drift allowed = 0.5

[root@kv-master-00 ~]# kubectl -n rook-ceph get ConfigMap rook-config-override -o yaml
apiVersion: v1
data:
  config: |
    [global]
    mon clock drift allowed = 0.5
kind: ConfigMap
metadata:
  creationTimestamp: "2019-10-18T14:08:39Z"
  name: rook-config-override
  namespace: rook-ceph
  ownerReferences:
  - apiVersion: ceph.rook.io/v1
    blockOwnerDeletion: true
    kind: CephCluster
    name: rook-ceph
    uid: d0bd3351-e630-44af-b981-550e8a2a50ec
  resourceVersion: "12831"
  selfLink: /api/v1/namespaces/rook-ceph/configmaps/rook-config-override
  uid: bdf1f1fb-967a-410b-a2bd-b4067ce005d2

[root@kv-master-00 ~]# kubectl -n rook-ceph delete pod $(kubectl -n rook-ceph get pods -o custom-columns=NAME:.metadata.name --no-headers| grep mon)
pod "rook-ceph-mon-a-8565577958-xtznq" deleted
pod "rook-ceph-mon-b-79b696df8d-qdcpw" deleted
pod "rook-ceph-mon-c-5df78f7f96-dr2jn" deleted

[root@kv-master-00 ~]# kubectl -n rook-ceph exec -it $toolbox sh
sh-4.2# ceph status                                                                         cluster:
    id:     5a0bbe74-ce42-4f49-813d-7c434af65aad
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 43s)
    mgr: a(active, since 9m)
    osd: 4 osds: 4 up (since 8m), 4 in (since 8m)
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   4.0 GiB used, 72 GiB / 76 GiB avail
    pgs:     
```



## References
* [Kubernetes getting started](https://kubernetes.io/docs/setup/)
* [KubeVirt Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer)
* [Ceph: free-software storage platform](https://ceph.io)
* [Ceph hardware recommendations](https://docs.ceph.com/docs/jewel/start/hardware-recommendations/)
* [Rook: Open-Source,Cloud-Native Storage for Kubernetes](https://rook.io/)
* [KubeVirt Userguide](https://kubevirt.io/user-guide/docs/latest/administration/intro.html#cluster-side-add-on-deployment)

