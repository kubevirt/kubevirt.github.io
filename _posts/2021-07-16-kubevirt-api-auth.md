---
layout: post
author: Mark DeNeve
title: Kubernetes Authentication Options using KubeVirt Client Library
description: This blog post discusses authentication methods that can be used with the KubeVirt client-go library.
navbar_active: Blogs
pub-date: July 16
pub-year: 2021
category: news
tags: [kubevirt, go, api, authentication]
comments: true
---

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Setup](#setup)
  - [Compiling our test application](#compiling-our-test-application)
- [Running our application externally leveraging a kubeconfig file](#running-our-application-externally-leveraging-a-kubeconfig-file)
  - [Using the default kubeconfig](#using-the-default-kubeconfig)
  - [Creating a kubeconfig for the service account](#creating-a-kubeconfig-for-the-service-account)
- [Running in a Kubernetes Cluster](#running-in-a-kubernetes-cluster)
- [Extending RBAC Role across Namespaces](#extending-rbac-role-across-namespaces)
- [Creating Custom RBAC Roles](#creating-custom-rbac-roles)
- [Conclusion](#conclusion)
- [References](#references)

## Introduction

Most interaction with the KubeVirt service can be handled using the _virtctl_ command, or raw yaml applied to your Kubernetes cluster. But what if you want to have more direct programmatic control over the instantiation and management of those virtual machines? The KubeVirt project supplies a Go client library for interacting with KubeVirt called [client-go](https://github.com/kubevirt/client-go). This library allows you to write your own applications that interact directly with the KubeVirt api quickly and easily. 

In this post, we will use a simple application to demonstrate how the KubeVirt client library authenticates with your Kubernetes cluster both in and out of your cluster. This application is based on the example application in the "client-go" library with a few small modifications to it, to allow for running both locally and within in the cluster. This tutorial assumes you have some knowledge of Go, and is not meant to be a Go training doc.

## Requirements

In order to compile and run the test application locally you will need to have the Go programming language installed on your machine. If you do not have the latest version of Go installed, follow the steps on the [Downloads](https://golang.org/dl/) page of the Go  web site before proceeding with the rest of the steps in this blog. The steps listed here were tested with Go version 1.16.

You will need a Kubernetes cluster running with the KubeVirt operator installed. If you do not have a cluster available, the easiest way to do this is to follow the steps outlined in the [Quick Start with Minikube](https://kubevirt.io/quickstart_minikube/) lab.

The example application we will be using to demonstrate the authentication methods lists out the VMI and VM instances in your cluster in the current namespace. If you do not have any running VMs in your cluster, be sure to create at least one new virtual machine instance in your cluster. For guidance in creating a quick test vm see the [Use KubeVirt](https://kubevirt.io/labs/kubernetes/lab1.html) lab.

## Setup

### Compiling our test application

Start by cloning the example application repo [https://github.com/xphyr/kubevirt-apiauth](https://github.com/xphyr/kubevirt-apiauth) and compiling our test application:

```shell
$ git clone https://github.com/xphyr/kubevirt-apiauth.git
$ cd kubevirt-apiauth/listvms
$ go build
```

Once the program compiles, test to ensure that the application compiled correctly. If you have a working Kubernetes context, running this command may return some values. If you do not have a current context, you will get an error. This is OK, we will discuss authentication next.

```shell
$ ./listvms
2021/06/23 16:51:28 cannot obtain KubeVirt vm list: Get "http://localhost:8080/apis/kubevirt.io/v1alpha3/namespaces/default/virtualmachines": dial tcp 127.0.0.1:8080: connect: connection refused
```

As long as the program runs, you are all set to move onto the next step.

## Running our application externally leveraging a kubeconfig file

The default authentication file for Kubernetes is the [kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file. We will not be going into details of this file, but you can click the link to goto the documentation on the kubeconfig file to learn more about it. All you need to know at this time is that when you use the _kubectl_ command you are using a kubeconfig file for your authentication.

### Using the default kubeconfig

If you haven't already done so, validate that you have a successful connection to your cluster with the "_kubectl_" command:

```shell
$ kubectl get nodes
NAME       STATUS   ROLES                  AGE     VERSION
minikube   Ready    control-plane,master   5d21h   v1.20.7
```

We now have a valid kubeconfig. On *nix OS such as Linux and OSX, this file is stored in your home directory at `~/.kube/config`. You should now be able to run our test application and get some results (assuming you have some running vms in your cluster).

```shell
$ ./listvms/listvms
Type                       Name       Namespace     Status
VirtualMachine             testvm     default       false
VirtualMachineInstance     testvm     default       Scheduled
```

This is great, but there is an issue. The authentication method we used is your primary Kubernetes authentication. It has roles and permissions to do many different things in your k8s cluster. Wouldn't it be better if we could scope that authentication and ensure that your application had a dedicated account, with only the proper permissions to interact with just what your application will need. This is what Kubernetes **Service Accounts** are for.

[Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/) are accounts for processes as opposed to users. By default they are scoped to a namespace, but you can give service accounts access to other namespaces through RBAC rules that we will discuss later. In this demo, we will be using the "_default_" project/namespace, so the service account we create will be initially scoped only to this namespace.

Start by creating a new service account called "mykubevirtrunner" using your default Kubernetes account:

```shell
$ kubectl create sa mykubevirtrunner
$ kubectl describe sa mykubevirtrunner
Name:                mykubevirtrunner
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   mykubevirtrunner-token-pd2mq
Tokens:              mykubevirtrunner-token-pd2mq
Events:              <none>
```

In the describe output you can see that a token and a mountable secret have been created. Let's take a look at the contents of the secret:

```shell
$ kubectl describe secret mykubevirtrunner-token-pd2mq
Name:         mykubevirtrunner-token-pd2mq
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: mykubevirtrunner
              kubernetes.io/service-account.uid: f401493b-658a-489d-bcce-0ccce39160a0

Type:  kubernetes.io/service-account-token

Data
====
namespace:  7 bytes
token:      eyJhbGciOiJS...
ca.crt:     1111 bytes

```

The data listed for the "token" key is the information we will use in the next step, your output will be much longer, it has been truncated for this document. Ensure when copying the value that you get the entire token value.

### Creating a kubeconfig for the service account

We will create a new kubeconfig file that leverages the service account and token we just created. The easiest way to do this is to create an empty kubeconfig file, and use the "_kubectl_" command to log in with the new token. Open a NEW terminal window. This will be the window we use for the service account. In this new terminal window start by setting the KUBECONFIG environment variable to point to a file in our local directory, and then using the "_kubectl_" command to generate a new kubeconfig file:

```shell
$ export KUBECONFIG=$(pwd)/sa-kubeconfig
$ kubectl config set-cluster minikube --server=https://<update IP address>:8443 --insecure-skip-tls-verify
$ kubectl config set-credentials mykubevirtrunner --token=<paste token from last step here>
$ kubectl config set-context minikube --cluster=minikube --namespace=default --user=mykubevirtrunner
$ kubectl config use-context minikube
```

We can test that the new kubeconfig file is working by running a kubectl command:

```shell
$ kubectl get pods
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:mykubevirtrunner" cannot list resource "pods" in API group "" in the namespace "default"
```

Note that the "User" is now listed as "_system:serviceaccount:default:mykubevirtrunner_" so we know we are using our new service account. Now try running our test program and note that it is using the service account as well:

```shell
$ listvms/listvms
2021/07/07 14:53:23 cannot obtain KubeVirt vm list: virtualmachines.kubevirt.io is forbidden: User "system:serviceaccount:default:mykubevirtrunner" cannot list resource "virtualmachines" in API group "kubevirt.io" in the namespace "default"
```

You can see we are now using our service account in our application, but that service account doesn't have the right permissions... We now need to assign a role to our service account to give it the proper API access. We will start simple and give the service account the **kubevirt.io:view** role, which will allow the service account to see the KubeVirt objects within the "_default_" namespace:

```shell
$ kubectl create clusterrolebinding kubevirt-viewer --clusterrole=kubevirt.io:view --serviceaccount=default:mykubevirtrunner
clusterrolebinding.rbac.authorization.k8s.io/kubevirt-viewer created
```

Now run the _listvms_ command again:

```shell
./listvms/listvms
Type                       Name                    Namespace     Status
VirtualMachineInstance     vm-fedora-ephemeral     myvms         Running
```

Success! Our application is now using the service account that we created for authentication to the cluster. The service account can be extended by adding additional default roles to the account, or by creating custom roles that limit the scope of the service account to only the exact actions you want to take. When you install KubeVirt you get a set of default roles including "View", "Edit" and "Admin". Additional details about these roles are available here: [KubeVirt Default RBAC Cluster Roles](https://kubevirt.io/user-guide/operations/authorization/)

## Running in a Kubernetes Cluster

So all of this is great if you want to run the application outside of your cluster ... but what if you want your application to run INSIDE you cluster. You could create a kubeconfig file, and add it to your namespace as a secret and then mount that secret as a volume inside your pod, but there is an easier way that continues to leverage the service account that we created. By default Kubernetes creates a few environment variables for every pod that indicate that the container is running within Kubernetes, and it makes a Kubernetes authentication token for the service account that the container is running as available at /var/run/secrets/kubernetes.io/serviceaccount/token. The client-go KubeVirt library can detect that it is running inside a Kubernetes hosted container and will transparently use the authentication token provided with no additional configuration needed.

A container image with the listvms binary is available at **quay.io/markd/listvms**. We can start a copy of this container using the deployment yaml file located in the 'listvms/listvms_deployment.yaml' file.

Switch back to your original terminal window that is using your primary kubeconfig file, and using the "_kubectl_" command deploy one instance of the test pod, and then check the logs of the pod:

```shell
$ kubectl create -f listvms/listvms_deployment.yaml
$ kubectl get pods
NAME                                      READY   STATUS    RESTARTS   AGE
listvms-7b8f865c8d-2zqqn                  1/1     Running   0          7m30s
virt-launcher-vm-fedora-ephemeral-4ljg4   2/2     Running   0          24h
$ kubectl logs listvms-7b8f865c8d-2zqqn
2021/07/07 19:06:42 cannot obtain KubeVirt vm list: virtualmachines.kubevirt.io is forbidden: User "system:serviceaccount:default:default" cannot list resource "virtualmachines" in API group "kubevirt.io" in the namespace "default"
```

> **NOTE:** Be sure to deploy this demo application in a namespace that contains at least one running VM or VMI.

The application is unable to run the operation, because it is running as the default service account in the "_default_" namespace. If you remember previously we created a service account in this namespace called "mykubevirtrunner". We need only update the deployment to use this service account and we should see some success. Use the "kubectl edit deployment/listvms" command to update the container spec to include the "serviceAccount: mykubevirtrunner" line as show below:

```yaml
    spec:
      containers:
        - name: listvms
          image: quay.io/markd/listvms
      serviceAccount: mykubevirtrunner
      securityContext: {}
      schedulerName: default-scheduler
```

This change will trigger Kubernetes to redeploy your pod, using the new serviceAccount. We should now see some output from our program:

```shell
$ kubectl get pods
NAME                                      READY   STATUS    RESTARTS   AGE
listvms-7b8f865c8d-2qzzn                  1/1     Running   0          7m30s
virt-launcher-vm-fedora-ephemeral-4ljg4   2/2     Running   0          24h
$ kubectl logs listvms-7b8f865c8d-2qzzn
Type                       Name                    Namespace     Status
VirtualMachineInstance     vm-fedora-ephemeral     myvms         Running
awaiting signal
```

## Extending RBAC Role across Namespaces

As currently configured, the mykubevirtrunner service account can only "view" KubeVirt resources within its own namespace. If we want to extend that ability to other namespaces, we can add the view role for other namespaces to the mykubevirtrunner serviceAccount.

```shell
$ kubectl create namespace myvms
$ <launch an addition vm here>
$ kubectl create clusterrolebinding kubevirt-viewer --clusterrole=kubevirt.io:view --serviceaccount=default:mykubevirtrunner -n myvms
```

We can test that the ServiceAccount has been updated to also have permissions to view in the "myvms" namespace by running our listvms command one more time, this time passing in the optional flag _--namespaces_. Switch to your terminal window that is using the service account kubeconfig file and run the following command:

```
$ listvms/listvms --namespaces myvms
additional namespaces to check are:  myvms
Checking the following namespaces:  [default myvms]
Type                       Name       Namespace     Status
VirtualMachine             testvm     default       false
VirtualMachineInstance     testvm     default       Scheduled
VirtualMachine             testvm     myvms         false
```

You can see that now, the ServiceAccount can view the vm and vmi that are in both the default namespace as well as the _myvms_ namespace.

## Creating Custom RBAC Roles

In this demo we used RBAC roles created as part of the KubeVirt install. You can also create custom RBAC roles for KubeVirt. Documentation on how this can be done is available in the KubeVirt documentation [Creating Customer RBAC Roles](https://kubevirt.io/user-guide/operations/authorization/#creating-custom-rbac-roles)

## Conclusion

It is possible to control and manage your KubeVirt machines with the use of Kubernetes service accounts and the "client-go" library. When using service accounts, you want to ensure that the account has the minimum role or permissions to do it's job to ensure the security of your cluster. The "client-go" library gives you options on how you authenticate with your Kubernetes cluster, allowing you to deploy your application both in and out of your Kubernetes cluster.

## References

[KubeVirt Client Go](https://github.com/kubevirt/client-go)

[KubeVirt API Access Control](https://kubevirt.io/2018/KubeVirt-API-Access-Control.html)

[KubeVirt Default RBAC Cluster Roles](https://kubevirt.io/user-guide/operations/authorization/)