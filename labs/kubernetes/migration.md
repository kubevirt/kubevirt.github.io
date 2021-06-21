---
layout: labs
title: Live Migration
permalink: /labs/kubernetes/migration
navbar_active: Labs
lab: kubernetes
order: 4
tags:
  [
    laboratory,
    kubevirt installation,
    feature-gate,
    VM,
    Live Migration,
    lab,
  ]
---

# Live Migration

[Live Migration](/2020/Live-migration.html) is a common virtualization feature
supported by KubeVirt where virtual machines running on one cluster node move
to another cluster node without shutting down the guest OS or its applications.

To experiment with KubeVirt live migration in a Minikube test environment, some
setup is required.

Start a minikube
cluster with the following requirements:

  * Two or more nodes
  * Flannel CNI plugin
  * Nested or Emulated virtualization (see the [Minikube Quickstart](/quickstart_minikube/)
  * The kubevirt addon for minikube

### Check the status of minikube and kubevirt

To check on minikube node statuses, run:
```bash
minikube status
```

This will return a report like this (two KVM2 nodes in this example):

```bash
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

minikube-m02
type: Worker
host: Running
kubelet: Running
```

Check that kubevirt fully deployed:

```bash
kubectl -n kubevirt get kubevirt
NAME       AGE     PHASE
kubevirt   3m20s   Deployed
```

## Enable Live Migration

Live migration is, at the time of writing, not a standard feature in KubeVirt. To enable the feature, create a `ConfigMap` in the "kubevirt" `Namespace` called "kubevirt-config".

```bash
{% include scriptlets/migration/01_enable_livemigration_feature.sh -%}
```

## Create a Virtual Machine

Next, create a VM. This lab uses the ["testvm"](/labs/manifests/vm.yaml) from [lab1](/labs/kubernetes/lab1.html), with an important edit.

Under `spec.template.spec.domain.devices.interfaces` instead of the default
network interface having a `bridge` type, this must be a `masquerade` type in
order to allow migration within minikube. A new YAML of `testvm` is provided
below.

```bash
{% include scriptlets/migration/02_create_testvm_masq.sh -%}
```

In a multi-node environment, it is helpful to know on which node a pod is running.
View its node using `-o wide`:

```bash
kubectl get pod -o wide
```

Notice in this example, the pod shows as running on `NODE` "minikube-m02":

```bash
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
virt-launcher-testvm-c8nzz   2/2     Running   0          32s   10.244.1.12   minikube-m02   <none>           <none>
```

## Start a Service on the Virtual Machine

Using `virtctl`, expose two ports for testing, `ssh` and `http/8080`:

```bash
{% include scriptlets/migration/03_expose_ports.sh -%}
```

Start by logging in to the console and running a simple web server using `netcat`:

```bash
{% include scriptlets/lab1/06_connect_to_testvm_console.sh -%}
```

The default user "cirros" and its password are mentioned on the console login
prompt, use them to log in. Next, run the following while loop to continuously
respond to any http connection attempt with a test message:

```bash
{% include scriptlets/migration/04_serve_http.sh -%}
```

Leave the loop running, and either break out of the console with `CTRL-]` or open
another terminal on the same machine.

To test the service, several bits of information will need to be coordinated.
To collect the minikube node IP address and the NodePort of the http service, run:

```bash
{% include scriptlets/migration/05_find_http.sh -%}
```

Now use `curl` to read data from the simple web service:

```bash
{% include scriptlets/migration/06_test_http.sh -%}
```

This should output `Migration test`. If all is well, it is time to migrate the
virtual machine to another node.

## Migrate VM

To migrate the `testvm` vmi from one node to the other, run:

```bash
virtctl migrate testvm
```

To ensure migration happens, watch the pods in "wide" view:

```bash
kubectl get pods -o wide
```

```bash
NAME                         READY   STATUS      RESTARTS   AGE    IP            NODE           NOMINATED NODE   READINESS GATES
virt-launcher-testvm-8src7   0/2     Completed   0          5m     10.244.1.14   minikube-m02   <none>           <none>
virt-launcher-testvm-zxlts   2/2     Running     0          21s    10.244.0.7    minikube       <none>           <none>
```

Notice the original virt-launcher pod has entered the `Completed` state and the virtual machine is now running on the `minikube` node.
Test the service previously started is still running:

```bash
{% include scriptlets/migration/06_test_http.sh -%}
```

Again, this should output `Migration test`.

## Summary

This lab is now concluded. This exercise has demonstrated the ability of
KubeVirt Live Migration to move a running virtual machine from one node to
another without requiring restart of running applications.
