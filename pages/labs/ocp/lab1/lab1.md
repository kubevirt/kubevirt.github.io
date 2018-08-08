## Student Connection Process

In this lab, we are going to leverage a process known as [`oc cluster up`](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md). `oc cluster up` leverages the local docker daemon and enables us to quickly stand up a local OpenShift Container Platform to start our evaluation. The key result of `oc cluster up` is a reliable, reproducible OpenShift environment to iterate on.

### Find your GCP Instance
This lab is designed to accommodate many students. As a result, each student will be given a VM running on GCP with nested virtualization, 4 vcpus and 12Gb of RAM. The naming convention for the lab VMs is:

**student\<number\>**.cnvlab.gce.sysdeseng.com

You will be assigned a number by the instructor.

Retrieve the keys from the [instructor host](http://cnv-tlv-web-svr.e2e.bos.redhat.com/cnv_rsa) so that you can _SSH_ into the instances by accessing the password protected directory. Download the `cnv_rsa`  file to your local machine and change the permissions of the file to 600. This web server is not public. You must be signed into the Red Hat VPN to access the key. Let an instructor know if you have any questions here.

```
wget http://cnv-tlv-web-svr.e2e.bos.redhat.com/cnv_rsa
chmod 600 cnv_rsa
```

### Connecting to your GCP Instance
This lab should be performed on **YOUR ASSIGNED GCP INSTANCE** as `cnv` user unless otherwise instructed.

**_NOTE_**: Please be respectful and only connect to your assigned instance. Every instance for this lab uses the same public key so you could accidentally (or with malicious intent) connect to the wrong system. If you have any issues, please inform an instructor.

```
ssh -i cnv_rsa cnv@student<number>.cnvlab.gce.sysdeseng.com
```

This concludes this section of the lab.

[Next Lab](../lab2/lab2.md)\
[Home](../../README.md)
