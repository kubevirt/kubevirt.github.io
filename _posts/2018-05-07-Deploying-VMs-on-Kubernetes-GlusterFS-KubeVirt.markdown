---
layout: post
author: rwsu
description: Deploying Virtual Machines on Kubernetes with GlusterFS+Heketi and KubeVirt
---

Kubernetes is traditionally used to deploy and manage containerized applications. Did you know Kubernetes can also be used to deploy and manage virtual machines? This guide will walk you through installing a Kubernetes environment backed by GlusterFS for storage and the KubeVirt add-on to enable deployment and management of VMs.

## Contents

* Prerequisites
* Known Issues
* Installing Kubernetes
* Installing GlusterFS and Heketi using gk-deploy
* Installing KubeVirt
* Deploying Virtual Machines

## Prerequisites

You should have access to at least three baremetal servers. One server will be the master Kubernetes node and other two servers will be the worker nodes. Each server should have a block device attached for GlusterFS, this is in addition to the ones used by the OS.

You may use virtual machines in lieu of baremetal servers. Performance may suffer and you will need to ensure your hardware supports nested virtualization and that the relevant kernel modules are loaded in the OS.

For reference, I used the following components and versions:

* baremetal servers with CentOS version 7.4 as the base OS
* latest version of Kubernetes (at the time v1.10.1)
* Weave Net as the Container Network Interface (CNI), v2.3.0
* [gluster-kubernetes](https://github.com/gluster/gluster-kubernetes) master commit 2a2a68ce5739524802a38f3871c545e4f57fa20a
* KubeVirt v0.4.1.

## Known Issues

* You may need to set SELinux to permissive mode prior to running "kubeadm init" if you see failures attributed to etcd in /var/log/audit.log.
* Prior to installing GlusterFS, you may need to disable firewalld until this issue is resolved: https://github.com/gluster/gluster-kubernetes/issues/471
* kubevirt-ansible install may fail in storage-glusterfs role: https://github.com/kubevirt/kubevirt-ansible/issues/219

## Installing Kubernetes

Create the Kubernetes cluster by using kubeadm. Detailed instructions can be found at https://kubernetes.io/docs/setup/independent/install-kubeadm/.

Use Weave Net as the CNI. Other CNIs may work, but I have only tested Weave Net.

If you are using only 2 servers as workers, then you will need to allow scheduling of pods on the master node because GlusterFS requires at least three nodes. To schedule pods on the master node, see "Master Isolation" in the kubeadm guide or execute this command:

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

Move onto the next step when your master and worker nodes are Ready.

```
[root@master ~]# kubectl get nodes
NAME                     STATUS    ROLES     AGE       VERSION
master.somewhere.com     Ready     master    6d        v1.10.1
worker1.somewhere.com    Ready     <none>    6d        v1.10.1
worker2.somewhere.com    Ready     <none>    6d        v1.10.1
```

And all of the pods in the kube-system namespace are Running.

```
[root@master ~]# kubectl get pods -n kube-system
NAME                                           READY     STATUS    RESTARTS   AGE
etcd-master.somewhere.com                      1/1       Running   0          6d
kube-apiserver-master.somewhere.com            1/1       Running   0          6d
kube-controller-manager-master.somewhere.com   1/1       Running   0          6d
kube-dns-86f4d74b45-glv4k                      3/3       Running   0          6d
kube-proxy-b6ksg                               1/1       Running   0          6d
kube-proxy-jjxs5                               1/1       Running   0          6d
kube-proxy-kw77k                               1/1       Running   0          6d
kube-scheduler-master.somewhere.com            1/1       Running   0          6d
weave-net-ldlh7                                2/2       Running   0          6d
weave-net-pmhlx                                2/2       Running   1          6d
weave-net-s4dp6                                2/2       Running   0          6d
```

### Installing GlusterFS and Heketi using gluster-kubernetes

The next step is to deploy GlusterFS and Heketi onto Kubernetes.

[GlusterFS](https://github.com/gluster/glusterfs) provides the storage system on which the virtual machine images are stored. [Heketi](https://github.com/heketi/heketi) provides the REST API that Kubernetes uses to provision GlusterFS volumes. The [gk-deploy tool](https://github.com/gluster/gluster-kubernetes) is used to deploy both of these components as pods in the Kubernetes cluster.

There is a detailed [setup guide for gk-deploy](https://github.com/gluster/gluster-kubernetes/blob/master/docs/setup-guide.md). Note each node must have a raw block device that is reserved for use by heketi and they must not contain any data or be pre-formatted. You can reset your block device to a useable state by running:

```
wipefs -a <path to device>
```

To aid you, below are the commands you will need to run if you are following the setup guide.

On all nodes:

```
# Open ports for GlusterFS communications
sudo iptables -I INPUT 1 -p tcp --dport 2222 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 24007 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 24008 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 49152:49251 -j ACCEPT
# Load kernel modules
sudo modprobe dm_snapshot
sudo modprobe dm_thin_pool
sudo modprobe dm_mirror
# Install glusterfs-fuse and git packages
sudo yum install -y glusterfs-fuse git
```

On the master node:

```
# checkout gluster-kubernetes repo
git clone https://github.com/gluster/gluster-kubernetes
cd gluster-kubernetes/deploy
```

Before running the gk-deploy script, we need to first create a topology.json file that maps the nodes present in the GlusterFS cluster and the block devices attached to each node. The block devices should be raw and unformatted. Below is a sample topology.json file for a 3 node cluster all operating in the same zone. The gluster-kubernetes/deploy directory also contains a sample topology.json file.

```json
# topology.json
{
  "clusters": [
    {
      "nodes": [
        {
          "node": {
            "hostnames": {
              "manage": [
                "master.somewhere.com"
              ],
              "storage": [
                "192.168.10.100"
              ]
            },
            "zone": 1
          },
          "devices": [
            "/dev/vdb"
          ]
        },
        {
          "node": {
            "hostnames": {
              "manage": [
                "worker1.somewhere.com"
              ],
              "storage": [
                "192.168.10.101"
              ]
            },
            "zone": 1
          },
          "devices": [
            "/dev/vdb"
          ]
        },
        {
          "node": {
            "hostnames": {
              "manage": [
                "worker2.somewhere.com"
              ],
              "storage": [
                "192.168.10.102"
              ]
            },
            "zone": 1
          },
          "devices": [
            "/dev/vdb"
          ]
        }
      ]
    }
  ]
}
```

Under "hostnames", the node's hostname is listed under "manage" and its IP address is listed under "storage". Multiple block devices can be listed under "devices". If you are using VMs, the second block device attached to the VM will usually be /dev/vdb. For multi-path, the device path will usually be /dev/mapper/mpatha. If you are using a second disk drive, the device path will usually be /dev/sdb.

Once you have your topology.json file and saved it in gluster-kubernetes/deploy, we can execute gk-deploy to create the GlusterFS and Heketi pods. You will need to specify an admin-key which will be used in the next step and will be discovered during the KubeVirt installation.

```
# from gluster-kubernetes/deploy
./gk-deploy -g -v -n kube-system --admin-key my-admin-key
```

Add the end of the installation, you will see:

```
heketi is now running and accessible via http://10.32.0.4:8080 . To run
administrative commands you can install 'heketi-cli' and use it as follows:

  # heketi-cli -s http://10.32.0.4:8080 --user admin --secret '<ADMIN_KEY>' cluster list

You can find it at https://github.com/heketi/heketi/releases . Alternatively,
use it from within the heketi pod:

  # /usr/bin/kubectl -n kube-system exec -i heketi-b96c7c978-dcwlw -- heketi-cli -s http://localhost:8080 --user admin --secret '<ADMIN_KEY>' cluster list

For dynamic provisioning, create a StorageClass similar to this:\
```

Take note of the URL for Heketi which will be used next step.

If successful, 4 additional pods will be shown as Running in the kube-system namespace.

```
[root@master deploy]# kubectl get pods -n kube-system
NAME                                                              READY     STATUS    RESTARTS   AGE
...snip...
glusterfs-h4nwf                                                   1/1       Running   0          6d
glusterfs-kfvjk                                                   1/1       Running   0          6d
glusterfs-tjm2f                                                   1/1       Running   0          6d
heketi-b96c7c978-dcwlw                                            1/1       Running   0          6d
...snip...
```

### Installing KubeVirt and setting up storage

The final component to install and which will enable us to deploy VMs on Kubernetes is KubeVirt.
We will use [kubevirt-ansible](https://github.com/kubevirt/kubevirt-ansible/) to deploy KubeVirt which will also help us configure a Secret and a StorageClass that will allow us to provision Persistent Volume Claims (PVCs) on GlusterFS.

Let's first clone the kubevirt-ansible repo.

```
git clone https://github.com/kubevirt/kubevirt-ansible
cd kubevirt-ansible
```

Edit the [inventory](https://github.com/kubevirt/kubevirt-ansible/blob/master/inventory) file in the kubevirt-ansible checkout. Modify the section that starts with "#BEGIN CUSTOM SETTINGS". As an example using the servers from above:

```
# BEGIN CUSTOM SETTINGS
[masters]
# Your master FQDN
master.somewhere.com

[etcd]
# Your etcd FQDN
master.somewhere.com

[nodes]
# Your nodes FQDN's
worker1.somewhere.com
worker2.somewhere.com

[nfs]
# Your nfs server FQDN

[glusterfs]
# Your glusterfs nodes FQDN
# Each node should have the "glusterfs_devices" variable, which
# points to the block device that will be used by gluster.
master.somewhere.com
worker1.somewhere.com
worker1.somewhere.com

#
# If you run openshift deployment
# You can add your master as schedulable node with option openshift_schedulable=true
# Add at least one node with lable to run on it router and docker containers
# openshift_node_labels="{'region': 'infra','zone': 'default'}"
# END CUSTOM SETTINGS
```

Now let's run the kubevirt.yml playbook:

```
ansible-playbook -i inventory playbooks/kubevirt.yml -e cluster=k8s -e storage_role=storage-glusterfs -e namespace=kube-system -e glusterfs_namespace=kube-system -e glusterfs_name= -e heketi_url=http://10.32.0.4:8080 -v
```

If successful, we should see 7 additional pods as Running in the kube-system namespace.

```
[root@master kubevirt-ansible]# kubectl get pods -n kube-system
NAME                                                              READY     STATUS    RESTARTS   AGE
virt-api-785fd6b4c7-rdknl                                         1/1       Running   0          6d
virt-api-785fd6b4c7-rfbqv                                         1/1       Running   0          6d
virt-controller-844469fd89-c5vrc                                  1/1       Running   0          6d
virt-controller-844469fd89-vtjct                                  0/1       Running   0          6d
virt-handler-78wsb                                                1/1       Running   0          6d
virt-handler-csqbl                                                1/1       Running   0          6d
virt-handler-hnlqn                                                1/1       Running   0          6d
```

## Deploying Virtual Machines

To deploy a VM, we must first grab a VM image in raw format, place the image into a PVC, define the VM in a yaml file, source the VM definition into Kubernetes, and then start the VM.

The [containerized data importer (CDI)](https://github.com/kubevirt/containerized-data-importer) is usually used to import VM images into Kubernetes, but there are some patches and additional testing to be done before the CDI can work smoothly with GlusterFS. For now, we will be placing the image into the PVC using a Pod that curls the image from the local filesystem using httpd.

On master or on a node where kubectl is configured correctly install and start httpd.

```
sudo yum install -y httpd
sudo systemctl start httpd
```

Download the cirros cloud image and convert it into raw format.

```
curl http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img -o /var/www/html/cirros-0.4.0-x86_64-disk.img
sudo yum install -y qemu-img
qemu-img convert /var/www/html/cirros-0.4.0-x86_64-disk.img /var/www/html/cirros-0.4.0-x86_64-disk.raw
```

Create the PVC to store the cirros image.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: gluster-pvc-cirros
 annotations:
   volume.beta.kubernetes.io/storage-class: kubevirt
spec:
 accessModes:
  - ReadWriteOnce
 resources:
   requests:
     storage: 5Gi
EOF
```

Check the PVC was created and has "Bound" status.

```
[root@master ~]# kubectl get pvc
NAME                 STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
gluster-pvc-cirros   Bound     pvc-843bd508-4dbf-11e8-9e4e-149ecfc53021   5Gi        RWO            kubevirt       2m
```

Create a Pod to curl the cirros image into the PVC.
Note: You will need to substitute <hostname> with actual hostname or IP address.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: image-importer-cirros
spec:
  restartPolicy: OnFailure
  containers:
  - name: image-importer-cirros
    image: kubevirtci/disk-importer
    env:
      - name: CURL_OPTS
        value: "-L"
      - name: INSTALL_TO
        value: /storage/disk.img
      - name: URL
        value: http://<hostname>/cirros-0.4.0-x86_64-disk.raw
    volumeMounts:
    - name: storage
      mountPath: /storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: gluster-pvc-cirros
EOF
```

Check and wait for the image-importer-cirros Pod to complete.

```
[root@master ~]# kubectl get pods
NAME                         READY     STATUS      RESTARTS   AGE
image-importer-cirros        0/1       Completed   0          28s
```

Create a Offline Virtual Machine definition for your VM and source it into Kubernetes.
Note the PVC containing the cirros image must be listed as the first disk under spec.domain.devices.disks.

```yaml
cat <<EOF | kubectl create -f -
apiVersion: kubevirt.io/v1alpha1
kind: OfflineVirtualMachine
metadata:
  creationTimestamp: null
  labels:
    kubevirt.io/ovm: cirros
  name: cirros
spec:
  running: false
  template:
    metadata:
      creationTimestamp: null
      labels:
        kubevirt.io/ovm: cirros
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: pvcdisk
            volumeName: cirros-pvc
          - disk:
              bus: virtio
            name: cloudinitdisk
            volumeName: cloudinitvolume
        machine:
          type: ""
        resources:
          requests:
            memory: 64M
      terminationGracePeriodSeconds: 0
      volumes:
      - cloudInitNoCloud:
          userDataBase64: IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        name: cloudinitvolume
      - name: cirros-pvc
        persistentVolumeClaim:
          claimName: gluster-pvc-cirros
status: {}
```

Finally start the VM.

```
export VERSION=v0.4.1
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/$VERSION/virtctl-$VERSION-linux-amd64
chmod +x virtctl
./virtctl start cirros
```

Wait for the VM to be in "Running" status.

```
[root@master ~]# kubectl get pods
NAME                         READY     STATUS      RESTARTS   AGE
image-importer-cirros        0/1       Completed   0          28s
virt-launcher-cirros-krvv2   0/1       Running     0          13s
```

Once it is running, we can then connect to its console.

```
./virtctl console cirros
```

Press enter if a login prompt doesn't appear.
