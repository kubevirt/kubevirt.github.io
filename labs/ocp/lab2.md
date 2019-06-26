---
layout: ocp
title: Set up your Environment
permalink: /labs/ocp/lab2
lab: ocp
order: 1
---

# Set up your Environment

For the sake of time, some of the required setup has already been taken care of on your GCP VM. For future reference though, the easiest way to get started is to head over to the documentation and follow the "[Getting Started](https://docs.okd.io/latest/getting_started/administrators.html)" instructions. The instructions cover getting started on Windows, MacOS, and Linux.

### Requirements

First, let's escalate privileges. The remaining commands will be run as _root_ on the GCP instance.

```bash
sudo -i
```

Create an SSH key that you will be using later.

```bash
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
```

Review the [`requirements.sh`](https://github.com/kubevirt/kubevirt-tutorial/commits/211ec7ce8c7b4c5f33974d3d1ac9b9e8cd06d3ee/administrator/requirements.sh) file. This script does the following:

- install *docker*, enable and start it as a service
- install *oc* and *kubectl* client
- pull relevant images

As GCP instances might randomly experience network issues at boot, double check requirements by relaunching the script. It will run missing steps if needed.

```bash
~/requirements.sh
```

### Openshift

All that's left to do is run OpenShift by executing the `openshift.sh` script in root home directory.

The remaining commands will be run as _root_ on the GCP instance. Review the `openshift.sh` file. Notice how additional flags are passed to `oc cluster up` to enable additional features like ansible service broker and to allow public access.

```bash
cat ~/openshift.sh
```

Now, let's start our local, containerized OpenShift environment. Running this script could take between 3-5 minutes.

```bash
~/openshift.sh
```

The resulting output should be something of this nature:

```bash
OpenShift server started.

The server is accessible via web console at:
    https://student002.cnvlab.gce.sysdeseng.com:8443

You are logged in as:
    User:     developer
    Password: <any value>

To login as administrator:
    oc login -u system:admin

Logged into "https://127.0.0.1:8443" as "system:admin" using existing credentials.

You have access to the following projects and can switch between them with 'oc project <projectname>':

    default
    kube-dns
    kube-proxy
    kube-public
    kube-service-catalog
    kube-system
  * myproject
    openshift
    openshift-apiserver
    openshift-automation-service-broker
    openshift-controller-manager
    openshift-core-operators
    openshift-infra
    openshift-node
    openshift-web-console

Using project "myproject".
origin
cluster role "cluster-admin" added: "developer"
```

The expected results here are that you recieved quite a bit of output. If you received something other than what is reported above, notify an instructor.

OK, so now that OpenShift is available, let's ask for a cluster status & take a look at our running containers:

```bash
oc version
  oc v3.10.0-rc.0+c20e215
  kubernetes v1.10.0+b81c8f8
  features: Basic-Auth GSSAPI Kerberos SPNEGO

  Server https://127.0.0.1:8443
  openshift v3.10.0-rc.0+ad6a1da-30
  kubernetes v1.10.0+b81c8f8
```

The important item from the `oc cluster status` command output is the `Web console URL`.

```bash
oc cluster status
  Web console URL: https://student002.cnvlab.gce.sysdeseng.com:8443/console/

  Config is at host directory
  Volumes are at host directory
  Persistent volumes are at host directory /root/openshift.local.clusterup/openshift.local.pv
  Data will be discarded when cluster is destroyed
```

This concludes this section of the lab.

---

[Next Lab]({{ site.baseurl }}/labs/ocp/lab3)\
[Previous Lab]({{ site.baseurl }}/labs/ocp/lab1)
