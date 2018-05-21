---
layout: post
author: karmab
description: A first look at using gluster cloning with kubevirt
---

Gluster seems like a good fit for storage in kubernetes and in particular in kubevirt. Still, as for other storage backends, we will likely need to use a golden set of images and deploy vms from them. 

That's where cloning feature of gluster comes at rescue!

## Contents

* Prerequisites
* Installing Gluster provisioner
* Using The cloning feature
* Conclusion
 
## Prerequisites

I assume you already have a running instance of openshift and kubevirt along with gluster and an already existing pvc where you copied a base operating system ( you can get those from [here](https://docs.openstack.org/image-guide/obtain-images.html))

For reference, I used the following components and versions:

* 3 baremetal servers with Rhel 7.4 as base OS
* Openshift and Cns 3.9
* KubeVirt latest

## Installing Gluster provisioner

### initial deployment

We will deploy the custom provisioner using [this template](../assets/2018-05-16-use-glustercloning-with-kubevirt/glusterfile-provisioner-template.yml), along with cluster rules located in [this file](../assets/2018-05-16-use-glustercloning-with-kubevirt/openshift-clusterrole.yaml)


Note that we also patch the image to use an existing one from gluster org located at docker.io instead of quay.io, as the corresponding repository is private by the time of this writing, and the heketi one, to make sure it has the code required to handle cloning

```
NAMESPACE="app-storage"
oc create -f openshift-clusterrole.yaml
oc process -f glusterfile-provisioner-template.yml | oc apply -f - -n $NAMESPACE
oc adm policy add-cluster-role-to-user cluster-admin -z glusterfile-provisioner -n $NAMESPACE
oc adm policy add-scc-to-user privileged -z glusterfile-provisioner
oc set image dc/heketi-storage heketi=gluster/heketiclone:latest  -n $NAMESPACE
oc set image dc/glusterfile-provisioner glusterfile-provisioner=gluster/glusterfileclone:latest  -n $NAMESPACE
```

And you will see something similar to this in your storage namespace

```
[root@master01 ~]# NAMESPACE="app-storage"
[root@master01 ~]# kubectl get pods -n $NAMESPACE
NAME                              READY     STATUS    RESTARTS   AGE
glusterfile-provisioner-3-vhkx6   1/1       Running   0          1d
glusterfs-storage-b82x4           1/1       Running   1          23d
glusterfs-storage-czthc           1/1       Running   0          23d
glusterfs-storage-z68hm           1/1       Running   0          23d
heketi-storage-2-qdrks            1/1       Running   0          6h
```

### additional configuration

for the custom provisioner to work, we need two additional things:

- a storage class pointing to it, but also containing the details of the current heketi installation
- a secret similar to the one used by the current heketi installation, but using a different *type*


You can use the following
```
NAMESPACE="app-storage"
oc get sc glusterfs-storage -o yaml
oc get secret heketi-storage-admin-secret -n $NAMESPACE-o yaml
```

then, create the following objects:

- glustercloning-heketi-secret secret in your storage namespace
- glustercloning storage class

for reference, here are samples of those files. 

Note how we change the type for the secret and add extra options for our storage class (in particular, enabling smartclone).

```
apiVersion: v1
data:
  key: eEt0NUJ4cklPSmpJb2RZcFpqVExSSjUveFV5WHI4L0NxcEtMME1WVlVjQT0=
kind: Secret
metadata:
  name: glustercloning-heketi-secret
  namespace: app-storage
type: gluster.org/glusterfile
```

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: glustercloning
parameters:
  restsecretname: glustercloning-heketi-secret
  restsecretnamespace: app-storage
  resturl: http://heketi-storage.192.168.122.10.xip.io
  restuser: admin
  smartclone: "true"
  snapfactor: "10"
  volumeoptions: group virt
provisioner: gluster.org/glusterfile
reclaimPolicy: Delete
```

The full set of supported parameters can be found [here](https://github.com/kubernetes-incubator/external-storage/blob/master/gluster/file/README.md)


## Using the cloning feature

Once deployed, you can now provision pvcs from a base origin

### Cloning single pvcs

For instance, provided you have an existing pvc named *cirros* containing this base operating system, and that this PVC contains an annotion of the following 

```
(...)
metadata:
 annotations:
  gluster.org/heketi-volume-id: f0cbbb29ef4202c5226f87708da57e5c
(...)
```

 you can create a cloned pvc with the following yaml ( note that we simply indicate a clone request in the annotations)

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: testclone1
  namespace: default
  annotations:
    k8s.io/CloneRequest: cirros
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: glustercloning
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
```

Once provisioned, the pvc will contain this additional annotation created by the provisioner

```
(...)
metadata:
 annotations:
      k8s.io/CloneOf: cirros

(...)
```

### Leveraging the feature in openshift templates

We can make direct use of the feature in [this openshift template](../assets/2018-05-16-use-glustercloning-with-kubevirt/template.yml) which would create the following objects:

- a persistent volume claim as a clone of an existing pvc (cirros by default)
- an offline virtual machine object
- additional services for ssh and http access

you can use it with something like

```
oc process -f template.yml -p Name=myvm | oc process -f - -n default
```

## Conclusion

cloning features in the storage backend allow us to simply use a given set of pvcs as base os for the deployment of our vms. this feature is growing in gluster, worth giving it a try!





