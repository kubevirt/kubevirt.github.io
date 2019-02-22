---
layout: post
author: karmab
description: Federated Kubevirt
navbar_active: Blogs
pub-date: Feb 22
pub-year: 2019
category: news
comments: true
---

# Federated Kubevirt

Federated Kubevirt is a reference implementation of deploying and managing [Kubevirt](https://kubevirt.io/) across multiple
[Kubernetes](https://kubernetes.io/) clusters using [Federation-v2](https://github.com/kubernetes-sigs/federation-v2).

Federation-v2 is an API and control-plane for actively managing multiple Kubernetes clusters and applications in those
clusters. This makes Federation-v2 a viable solution for managing Kubevirt deployments that span multiple Kubernetes
clusters.

## Federation-v2 Deployment

We assume federation is already deployed (using latest stable version) and you have configured your two clusters with context `cluster1` and `cluster2`

## Federated Kubevirt Deployment

We create kubevirt namespace on first cluster:

```
kubectl create ns kubevirt
```

We then create [a placement](/assets/2019-02-22-federated-kubevirt/federated_namespace.yaml) for this namespace to get replicated to the second cluster.

```
kubectl create -f federated_namespace.yaml
```

NOTE: This yaml file was generated for version 0.14.0. but feel free to edit in order to use a more recent version of the operator

We create the federated objects required as per kubevirt deployment:

```
kubefed2 enable ClusterRoleBinding
kubefed2 enable CustomResourceDefinition
```
And [federated kubevirt](/assets/2019-02-22-federated-kubevirt/federated_kubevirt-operator.yaml) itself, with placements so that it gets deployed at both sites.

```
kubectl create -f federated_kubevirt-operator.yaml
```

This gets kubevirt operator deployed at both sites, which creates the Custom Resource definition *Kubevirt*. We then deploy kubevirt by federating this CRD and creates [an instance of it](/assets/2019-02-22-federated-kubevirt/federated_kubevirt-cr.yaml).

```
kubefed2 enable kubevirts
kubectl create -f federated_kubevirt-cr.yaml
```

To help starting/stopping vms and connecting to consoles, we install virtctl (which is aware of contexts):

```
VERSION="v0.14.0"
wget https://github.com/kubevirt/kubevirt/releases/download/$VERSION/virtctl-$VERSION-linux-amd64
mv virtctl-$VERSION-linux-amd64 /usr/bin/virtctl
chmod +x /usr/bin/virtctl
```

## Kubevirt Deployment Verification

Verify that all Kubevirt pods are running in the clusters:

```bash
$ for c in cluster1 cluster2; do kubectl get pods -n kubevirt --context ${c} ; done
NAME                               READY     STATUS    RESTARTS   AGE
virt-api-578cff4f56-2dsml          1/1       Running   0          3m
virt-api-578cff4f56-8mk27          1/1       Running   0          3m
virt-controller-7d8c4fbc4c-pfwll   1/1       Running   0          3m
virt-controller-7d8c4fbc4c-xvlvr   1/1       Running   0          3m
virt-handler-plfg7                 1/1       Running   0          3m
virt-operator-67c86544f7-pnjjk     1/1       Running   0          5m
NAME                               READY     STATUS    RESTARTS   AGE
virt-api-578cff4f56-jjbmf          1/1       Running   0          3m
virt-api-578cff4f56-m6g2c          1/1       Running   0          3m
virt-controller-7d8c4fbc4c-tt9tz   1/1       Running   0          3m
virt-controller-7d8c4fbc4c-zf6hh   1/1       Running   0          3m
virt-handler-bldss                 1/1       Running   0          3m
virt-operator-67c86544f7-zz5jc     1/1       Running   0          5m
```

Now that kubevirt is up and created its own custom resource types, we federate them:

```
kubefed2 enable virtualmachines
kubefed2 enable virtualmachineinstances
kubefed2 enable virtualmachineinstancepresets
kubefed2 enable virtualmachineinstancereplicasets
kubefed2 enable virtualmachineinstancemigrations
```

For demo purposes, we also federate persistent volume claims:

```
kubefed2 enable persistentvolumeclaim
```

## Demo Workflow

We create a [federated persistent volume claim](/assets/2019-02-22-federated-kubevirt/federated_pvc.yaml), pointing to an existing pv created at both sites, against the same nfs server:

```
kubectl create -f federated_pvc.yaml
```

We then create a [federated virtualmachine](/assets/2019-02-22-federated-kubevirt/federated_vm.yaml), with a placement so that it's only created at cluster1

```
kubectl create -f federated_vm.yaml
```

We can check how its underlying pod only got created at one site:

```bash
$ for c in cluster1 cluster2; do kubectl get pods --context ${c} ; done
NAME                          READY     STATUS    RESTARTS   AGE
virt-launcher-testvm2-9dq48   2/2       Running   0          6m
No resources found.
```

Once the vm is up, we connect to it and format its secondary disk, put some data there

Playing with placement resource, we have it stopping at cluster1 and launch at cluster2.

```
kubectl patch federatedvirtualmachineplacements  testvm2 --type=merge -p '{"spec":{"clusterNames": ["cluster2"]}}'
```

We can then connect there and see how the data is still available!!!

# Final Thoughts

Federating Kubevirt allows interesting use cases around kubevirt like disaster recovery scenarios.

More over, the pattern used to federate this product can be seen as a generic way to federate modern applications:

- federate operator
- federate the CRD deploying the app (either at both sites or selectively)
- federate the CRDS handled by the app
