---
layout: post
author: arthursens
description: This blog post guides users on how to monitor linux based VMs from the inside with node-exporter and expose metrics to a Prometheus server
navbar_active: Blogs
category: uncategorized
tags:
  [
    "kubevirt",
    "Kubernetes",
    "virtual machine",
    "VM",
    "prometheus",
    "prometheus-operator",
    "node-exporter",
    "monitoring",
  ]
comments: true
title: Monitoring KubeVirt VMs from the inside
pub-date: October 21
pub-year: 2020
---

# Monitoring KubeVirt VMs from the inside

This blog post will guide you on how to monitor KubeVirt Linux based VirtualMachines with Prometheus [node-exporter](https://github.com/prometheus/node_exporter). Since node_exporter will run inside the VM and expose metrics at an HTTP endpoint, you can use this same guide to expose custom applications that expose metrics in the Prometheus format.

## Environment

This set of tools will be used on this guide:
* [Helm v3](https://github.com/helm/helm) - To deploy the Prometheus-Operator.
* [minikube](https://github.com/kubernetes/minikube) - Will provide us a k8s cluster, you are free to choose any other k8s provider though.
* [kubectl](https://github.com/kubernetes/kubectl) - To deploy different k8s resources
* virtctl - to interact with KubeVirt VirtualMachines, can be downloaded from the [KubeVirt repo](https://github.com/kubevirt/kubevirt/releases).

## Deploy Prometheus Operator

Once you have your k8s cluster, with minikube or any other provider, the first step will be to deploy the Prometheus Operator. The reason is that the KubeVirt CR, when installed on the cluster, will detect if the ServiceMonitor CR already exists. If it does, then it will create ServiceMonitors configured to monitor all the KubeVirt components (virt-controller, virt-api, and virt-handler) out-of-the-box.

Although monitoring KubeVirt itself is not covered in this guide, it is a good practice to always deploy the Prometheus Operator before deploying KubeVirt.

To deploy the Prometheus Operator, you will need to create its namespace first, e.g. `monitoring`:
```
kubectl create ns monitoring
```
Then deploy the operator in the new namespace:
```
helm fetch stable/prometheus-operator
tar xzf prometheus-operator*.tgz
cd prometheus-operator/ && helm install -n monitoring -f values.yaml kubevirt-prometheus stable/prometheus-operator
```
After everything is deployed, you can delete everything that was downloaded by helm:
```
cd ..
rm -rf prometheus-operator*
```

One thing to keep in mind is the release name we added here: `kubevirt-prometheus`. The release name will be used when declaring our `ServiceMonitor` later on..

## Deploy KubeVirt Operators and KubeVirt CustomResources

Alright, the next step will be deploying KubeVirt itself. We will start with its operator.

We will fetch the latest version, then use `kubectl create` to deploy the manifest directly from Github::
```
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- - | sort -V | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs)
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
```

Before deploying the KubeVirt CR, make sure that all kubevirt-operator replicas are ready, you can do that with:
```
kubectl rollout status -n kubevirt deployment virt-operator
```

After that, we can deploy KubeVirt and wait for all it’s components to get ready in a similar manner:
```
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
kubectl rollout status -n kubevirt deployment virt-api
kubectl rollout status -n kubevirt deployment virt-controller
kubectl rollout status -n kubevirt daemonset virt-handler
```

If we want to monitor VMs that can restart, we want our node-exporter to be persisted and, thus, we need to set up persistent storage for them. [CDI](https://github.com/kubevirt/containerized-data-importer) will be the component responsible for that, so we will deploy it’s operator and custom resource as well. As always, waiting for the right components to get ready before proceeding:

```
export CDI_VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VERSION/cdi-operator.yaml
kubectl rollout status -n cdi deployment cdi-operator

kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VERSION/cdi-cr.yaml
kubectl rollout status -n cdi deployment cdi-apiserver
kubectl rollout status -n cdi deployment cdi-uploadproxy
kubectl rollout status -n cdi deployment cdi-deployment
```


## Deploying a VirtualMachine with persistent storage

Alright, cool. We have everything we need now. Let's setup the VM.

We will start with the PersistenVolumes required by [CDI’s DataVolume](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/datavolumes.md) resources. Since I’m using minikube with no dynamic storage provider, I’ll be creating 2 PV with a reference to the PVCs that will claim them. Notice `claimRef` in each of the PVs.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-volume
spec:
  storageClassName: ""
  claimRef: 
    namespace: default
    name: cirros-dv
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 2Gi
  hostPath:
    path: /data/example-volume/
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-volume-scratch
spec:
  storageClassName: ""
  claimRef: 
    namespace: default
    name: cirros-dv-scratch
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 2Gi
  hostPath:
    path: /data/example-volume-scratch/
```

With the persistent storage in place, we can create our VM with the following manifest:

```yaml
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: monitorable-vm
spec:
  running: true
  template:
    metadata: 
      name: monitorable-vm
      labels: 
        prometheus.kubevirt.io: "node-exporter"
    spec:
      domain:
        resources:
          requests:
            memory: 1024Mi
        devices:
          disks:
          - disk:
              bus: virtio
            name: my-data-volume
      volumes:
      - dataVolume:
          name: cirros-dv
        name: my-data-volume
  dataVolumeTemplates: 
  - metadata:
      name: "cirros-dv"
    spec:
      source:
          http: 
             url: "https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img"
      pvc:
        storageClassName: ""
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: "2Gi"
```

Notice that KubeVirt's VirtualMachine resource has a virtual machine template and a dataVolumeTemplate. On the virtual machine template, it is important noticing that we named our VM `monitorable-vm`, and we will use this name to connect to its console with `virtctl` later on. The label we've added, `prometheus.kubevirt.io: "node-exporter"`, is also important, since we'll use it when [configuring Prometheus to scrape the VM's node-exporter](#Configuring-Prometheus-to-scrape-the-VM's-node-exporter)

On dataVolumeTemplate, it is important noticing that we named the PVC `cirros-dv` and the DataVolume resource will create 2 PVCs with that, `cirros-dv` and `cirros-dv-scratch`. Notice that `cirros-dv` and `cirros-dv-scratch` are the names referenced on our PersistentVolume manifests. The names must match for this to work. 

## Installing the node-exporter inside the VM

Once the VirtualMachineInstance is running, we can connect to its console using `virtctl console monitorable-vm`. If user and password are required, provide your credentials accordingly. If you are using the same disk image from this guide, the user and password are `cirros` and `gocubsgo` respectively.

The following script will install node-exporter and configure the VM to always start the exporter when booting:
```shell
curl -LO -k https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
gunzip -c node_exporter-1.0.1.linux-amd64.tar.gz | tar xopf -
./node_exporter-1.0.1.linux-amd64/node_exporter &

sudo /bin/sh -c 'cat > /etc/rc.local <<EOF
#!/bin/sh
echo "Starting up node_exporter at :9100!"

/home/cirros/node_exporter-1.0.1.linux-amd64/node_exporter 2>&1 > /dev/null &
EOF'
sudo chmod +x /etc/rc.local
```
*P.S.: If you are using a different base image, please configure node-exporter to start at boot time accordingly*

## Configuring Prometheus to scrape the VM's node-exporter

To configure Prometheus to scrape the node-exporter (or other aplications) is really simple. All we need is to create a new `Service` and a `ServiceMonitor`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: monitorable-vm-node-exporter
  labels:
    prometheus.kubevirt.io: "node-exporter"
spec:
  ports:
  - name: metrics 
    port: 9100 
    targetPort: 9100
    protocol: TCP
  selector:
    prometheus.kubevirt.io: "node-exporter"
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kubevirt-node-exporters-servicemonitor
  namespace: monitoring
  labels:
    prometheus.kubevirt.io: "node-exporter"
    release: monitoring
spec:
  namespaceSelector:
    any: true
  selector:
    matchLabels:
      prometheus.kubevirt.io: "node-exporter"
  endpoints:
  - port: metrics
    interval: 15s
```

Let's break this down just to make sure we set up everything right. Starting with the `Service`:
```yaml
spec:
  ports:
  - name: metrics 
    port: 9100 
    targetPort: 9100
    protocol: TCP
  selector:
    prometheus.kubevirt.io: "node-exporter"
```
On the specification, we are creating a new port named `metrics` that will be redirected to every pod labeled with `prometheus.kubevirt.io: "node-exporter"`, at port 9100, which is the default port number for the node-exporter.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: monitorable-vm-node-exporter
  labels:
    prometheus.kubevirt.io: "node-exporter"
```
We are also labeling the Service itself with `prometheus.kubevirt.io: "node-exporter"`, that will be used by the `ServiceMonitor` object.

Now let's take a look at our `ServiceMonitor` specification:
```yaml
spec:
  namespaceSelector:
    any: true
  selector:
    matchLabels:
      prometheus.kubevirt.io: "node-exporter"
  endpoints:
  - port: metrics
    interval: 15s
```
Since our ServiceMonitor will be deployed at the `monitoring` namespace, but our service is at the `default` namespace, we need `namespaceSelector.any=true`.

We are also telling our ServiceMonitor that Prometheus needs to scrape endpoints from services labeled with `prometheus.kubevirt.io: "node-exporter"` and which ports are named `metrics`. Luckily, that's exactly what we did with our `Service`!

One last thing to keep an eye on. Prometheus configuration can be set up to watch multiple ServiceMonitors. We can see which ServiceMonitors our Prometheus is watching with the following command: 
```
# Look for Service Monitor Selector
kubectl describe -n monitoring prometheuses.monitoring.coreos.com monitoring-prometheus-oper-prometheus
```

Make sure our ServiceMonitor has all labels required by Prometheus' `Service Monitor Selector`. One common selector is the release name that we’ve set when deploying our Prometheus with helm!

## Testing

You can do a quick test by port-forwarding Prometheus web UI and executing some PromQL:

```
kubectl port-forward -n monitoring prometheus-monitoring-prometheus-oper-prometheus-0 9090:9090
```

To make sure everything is working, access `localhost:9090/graph` and execute the PromQL `up{pod=~"virt-launcher.*"}`. Prometheus should return data that is being collected from `monitorable-vm`'s node-exporter.

You can play around with `virtctl`, stop and starting the VM to see how the metrics behave. You will notice that when stopping the VM with `virtctl stop monitorable-vm`, the VirtualMachineInstance is killed and, thus, so is it's pod. This will result with our service not being able to find the pod's endpoint and then it will be removed from Prometheus' targets.

With this behavior, alerts like the one below won’t work since our target is literally gone, not down.
```yaml
- alert: KubeVirtVMDown
    expr: up{pod=~"virt-launcher.*"} == 0
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: KubeVirt VM {{ $labels.pod }} is down.
```

**BUT**, if the VM is constantly crashing without being stopped, the pod won’t be killed and the target will still be monitored. Node-exporter will never start or will go down constantly alongside the VM, so an alert like this might work:
```yaml
- alert: KubeVirtVMCrashing
    expr: up{pod=~"virt-launcher.*"} == 0 or changes(up{pod=~"virt-launcher.*"}[5m]) > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: KubeVirt VM {{ $labels.pod }} is constantly crashing before node-exporter starts at boot or has crashed at least once in the last 5 minutes.
```