---
layout: post
author: awels
description: Deploying KubeVirt on a single oVirt VM
---

In this blog post we are exploring the possibilities of deploying Kube Virt on top of Open Shift which is running inside an oVirt VM. First we must prepare the environment. In my testing I created a VM with 4 cpus, 14G memory and a 100G disk. I then installed Centos 7.4 minimal on it. I also have nested virtualization
enabled on my hosts, so any VMs I create can run VMs inside them. These instructions are specific to oVirt, however if you are running another virtualization
platform that can nested virtualization this will also work.

For this example I chose to use a single VM for everything, but I could have done different VMs for my master/nodes/storage/etc, for simplicity I used a single
VM.

## Preparing the VM

First we will need to enable epel and install some needed tools, like git to get at the source, and ansible to do the deploy:

As _root_:
```bash
$ yum -y install epel-release
$ yum -y install ansible git wget
```
_optional_
_Install ovirt-guest-agent so you can see information in your oVirt admin view._

As _root_:
```bash
$ yum -y install ovirt-guest-agent
$ systemctl start ovirt-guest-agent
$ systemctl enable ovirt-guest-agent
```
_Make a template out of the VM, so if something goes wrong you have a good starting point to try again._

Make sure the VM has a fully qualified domain name, using either DNS or editing /etc/hosts.

As we are going to install openshift we will need to install the openshift client tooling from [openshift github](https://github.com/openshift/origin/releases)
in this article I opted to simply copy the oc command into /usr/bin, but anywhere in your path will do. Alternatively you can add oc to your PATH.

As _root_:
```bash
$ wget https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz
$ tar zxvf openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz
$ cp openshift-origin-client-tools-v3.9.0-191fece-linux-64bit/oc /usr/bin
```

Next we will install docker and configure it for use with open shift.

As _root_:
```bash
$ yum -y install docker
```

We need to setup an insecure registry in docker before we can start open shift. To do this we must add:
**INSECURE_REGISTRY="--insecure-registry 172.30.0.0/16"**
to the end of /etc/sysconfig/docker

Now we can start docker.

As _root_:
```bash
$ systemctl start docker
$ systemctl enable docker
```

Now we are ready to test if we can bring our cluster to up.

As _root_:
```bash
$ oc cluster up
```

## Installing kube virt with ansible
Now that we have everything configured we can the rest as a regular user. Also note that if you had an existing cluster you can could have skipped the previous section.

Clone the kube-virt ansible repo, and setup the ansible galaxy roles needed to deploy.

As _user_:
```bash
$ git clone https://github.com/kubevirt/kubevirt-ansible
$ cd kubevirt-ansible
$ mkdir $HOME/galaxy-roles
$ ansible-galaxy install -p $HOME/galaxy-roles -r requirements.yml
$ export ANSIBLE_ROLES_PATH=$HOME/galaxy-roles
```

Now that we are in the kubevirt-ansible directory, we have to edit the inventory file on where we are going to deploy the different open shift nodes.
Because we opted to install everything on a single VM the FQDN we enter is the same as the one we defined for our VM. Had we had different nodes we would
enter the FQDN of each in the inventory file. Lets assume our VMs FQDN is kubevirt.demo, we would changed the inventory file as follows:

As _user_:
```
[masters]
kubevirt.demo
[etcd]
kubevirt.demo
[nodes]
kubevirt.demo openshift_node_labels="{'region': 'infra','zone': 'default'}" openshift_schedulable=true
[nfs]
kubevirt.demo
```

In order to allow ansible to ssh into the box using ssh keys instead of a password we will need to generate some, assuming we don't have these
configured already:

As _root_:
```base
$ ssh-keygen -t rsa
```

Fill out the information in the questions, which will generate two files in /root/.ssh, id_rsa and id_rsa.pub. The id_rsa.pub is the public key which will allow
ssh to verify your identify when you ssh into a machine. Since we are doing all of this on the same machine, we can simply append the contents of
id_rsa.pub to authorized_keys in /root/.ssh. If that file doesn't exist you can simply copy id_rsa.pub to authorized_keys. If you are deploying to multiple hosts
you need to append the contents of id_rsa.pub on each host.

Next we need to configure docker storage, one can write a whole book about how to do that, so I will post a [link](https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage) to the installation document and for now go with the defaults which are not recommended for production, but since this is an introduction its fine.

As _root_:
```bash
$ docker-storage-setup
```

Lets double check the cluster is up before we start running the ansible play books.

As _root_:
```bash
$ oc cluster up
```

Install kubernetes.

As _root_:
```bash
$ ansible-playbook -i inventory playbooks/cluster/kubernetes/config.yml
```

Disable selinux on all hosts, this hopefully won't be needed in the future.

As _root_:
```bash
$ ansible-playbook -i inventory playbooks/selinux.yml
```

log in as admin to give developer user rights.

As _root_:
```bash
$ oc login -u system:admin
$ oc adm policy add-cluster-role-to-user cluster-admin developer
```

Log in as the developer user.

As _user_:
```bash
$ oc login -u developer
```
The password for the developer user is developer. Now finally deploy kubevirt.

As _user_:
```bash
$ ansible-playbook -i localhost playbooks/kubevirt.yml -e@vars/all.yml
```

Verify that the pods are running, you should be in the kube-system namespace, if not switch with oc project kube-system.

As _user_:
```bash
$ kubectl get pods
NAME                               READY     STATUS    RESTARTS   AGE
virt-api-747745669-mswk8           1/1       Running   0          10m
virt-api-747745669-t9dsp           1/1       Running   0          10m
virt-controller-648945bbcb-ln7dv   1/1       Running   0          10m
virt-controller-648945bbcb-nxrj8   0/1       Running   0          10m
virt-handler-6zh77                 1/1       Running   0          10m
```

Now that we have kube virt up and running we are ready to try and start a VM. Lets install virtctl to make it easier to
start and stop VMs. The latest available version while writing this was 0.4.1.

As _user_:
```bash
$ export VERSION=v0.4.1
$ curl -L -o virtctl \
    https://github.com/kubevirt/kubevirt/releases/download/$VERSION/virtctl-$VERSION-linux-amd64
$ chmod +x virtctl
```

Lets grab the demo VM specification from the kubevirt github page.

As _user_:
```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
```

Now we can start the VM.

As _user_:
```bash
$ ./virtctl start testvm
```

Now a new pod will be running that is controlling the VM.

As _user_:
```bash
$ kubectl get pods
NAME                               READY     STATUS    RESTARTS   AGE
virt-api-747745669-mswk8           1/1       Running   0          15m
virt-api-747745669-t9dsp           1/1       Running   0          15m
virt-controller-648945bbcb-ln7dv   1/1       Running   0          15m
virt-controller-648945bbcb-nxrj8   0/1       Running   0          15m
virt-handler-6zh77                 1/1       Running   0          15m
virt-launcher-testvm-gv5nt         2/2       Running   0          23s
```

Congratulations you now have a VM running in openshift using kubevirt inside an oVirt VM.

## Usefule resources
- [**KubeVirt**](https://github.com/kubevirt/kubevirt)
- [**KubeVirt Ansible**](https://github.com/kubevirt/kubevirt-ansible)
- [**Minikube kubevirt Demo**](https://github.com/kubevirt/demo)
- [**Kubectl installation**](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-native-package-management)
