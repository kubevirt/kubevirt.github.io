---
layout: post
author: Ram Lavi
title: Load-balancer for virtual machines on bare metal Kubernetes clusters
description: This post illustrates setting up a virtual machine with MetalLB LoadBalancer service.
navbar_active: Blogs
pub-date: May 03
pub-year: 2022
category: news
tags:
  [
    "Kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "load-balancer",
    "MetalLB",
  ]
comments: true
---

## Introduction

Over the last year, Kubevirt and MetalLB have shown to be powerful duo in order to support fault-tolerant access to an application on virtual machines through an external IP address. 
As a Cluster administrator using an on-prem cluster without a network load-balancer, now it's possible to use MetalLB operator to provide load-balancer capabilities (with Services of type `LoadBalancer`) to virtual machines.

## MetalLB

[MetalLB](https://metallb.universe.tf/) allows you to create Kubernetes services of type `LoadBalancer`, and provides network load-balancer implementation in on-prem clusters that don’t run on a cloud provider.
MetalLB is responsible for assigning/unassigning an external IP Address to your service, using IPs from pre-configured pools. In order for the external IPs to be announced externally, MetalLB works in 2 modes, Layer 2 and BGP:

- Layer 2 mode (ARP/NDP):

  This mode - which actually does not implement real load-balancing behavior - provides a failover mechanism where a single node owns the `LoadBalancer` service, until it fails, triggering another node to be chosen as the service owner. This configuration mode makes the IPs reachable from the local network.  
  In this method, the MetalLB speaker pod announces the IPs in ARP (for IPv4) and NDP (for IPv6) protocols over the host network. From a network perspective, the node owning the service appears to have multiple IP addresses assigned to a network interface. After traffic is routed to the node, the service proxy sends the traffic to the application pods. 

- BGP mode:

  This mode provides real load-balancing behavior, by establishing BGP peering sessions with the network routers - which advertise the external IPs of the `LoadBalancer` service, distributing the load over the nodes.

To read more on MetalLB concepts, implementation and limitations, please read [its documentation](https://metallb.universe.tf/concepts/).

## Demo: Virtual machine with external IP and MetalLB load-balancer

With the following recipe we will end up with a nginx server running on a virtual machine, accessible outside the cluster using MetalLB load-balancer with Layer 2 mode.

### Demo environment setup

We are going to use [kind](https://kind.sigs.k8s.io) provider as an ephemeral Kubernetes cluster.

Prerequirements:
- First install kind on your machine following its [installation guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).
- To use kind, you will also need to [install docker](https://docs.docker.com/install/).

#### External IPs on macOS and Windows

This demo runs Docker on Linux, which allows sending traffic directly to the load-balancer's external IP if the IP space is within the docker IP space.
On macOS and Windows however, docker does not expose the docker network to the host, rendering the external IP unreachable from other kind nodes. In order to workaround this, one could expose pods and services using extra port mappings as shown in the extra port mappings section of kind's [Configuration Guide](https://kind.sigs.k8s.io/docs/user/configuration#extra-port-mappings).

### Deploying cluster

To start a kind cluster:
```bash
kind create cluster
```

In order to interact with the specific cluster created:
```bash
kubectl cluster-info --context kind-kind
```

### Installing components

#### Installing MetalLB on the cluster

There are [many ways](https://metallb.universe.tf/installation/) to install MetalLB. For the sake of this example, we will install MetalLB via manifests. To do this, follow this [guide](https://metallb.universe.tf/installation/#installation-by-manifest). 
Confirm successful installation by waiting for MetalLB pods to have a status of Running:
```bash
kubectl get pods -n metallb-system --watch
```

#### Installing Kubevirt on the cluster

Following Kubevirt [user guide](https://kubevirt.io/user-guide/operations/installation/#installing-kubevirt-on-kubernetes) to install released version v0.51.0
```bash
export RELEASE=v0.51.0
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml"
kubectl -n kubevirt wait kv kubevirt --timeout=360s --for condition=Available
```

Now we have a Kubernetes cluster with all the pieces to start the Demo.

### Network resources configuration

#### Setting Address Pool to be used by the LoadBalancer

In order to complete the Layer 2 mode configuration, we need to set a range of IP addresses for the LoadBalancer to use.
On Linux we can use the docker kind network (macOS and Windows users see [External IPs Prerequirement](#external-ips-on-macos-and-windows)), so by using this command:

```bash
docker network inspect -f '{{.IPAM.Config}}' kind
```

You should get the subclass you can set the IP range from. The output should contain a cidr such as 172.18.0.0/16.
Using this result we will create the following Layer 2 address pool with 172.18.1.1-172.18.1.16 range:

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: addresspool-sample1
      protocol: layer2
      addresses:
      - 172.18.1.1-172.18.1.16
EOF
```

### Network utilization

#### Spin up a Virtual Machine running Nginx

Now it's time to start-up a virtual machine running nginx using the following yaml.
The virtual machine has a `metallb-service=nginx` we created to use when creating the service.
```yaml
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: fedora-nginx
  namespace: default
  labels:
    metallb-service: nginx
spec:
  running: true
  template:
    metadata:
      labels:
        metallb-service: nginx
    spec:
      domain:
        devices:
          disks:
            - disk:
                bus: virtio
              name: containerdisk
            - disk:
                bus: virtio
              name: cloudinitdisk
          interfaces:
            - masquerade: {}
              name: default
        resources:
          requests:
            memory: 1024M
      networks:
        - name: default
          pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
        - containerDisk:
            image: kubevirt/fedora-cloud-container-disk-demo
          name: containerdisk
        - cloudInitNoCloud:
            userData: |-
              #cloud-config
              password: fedora
              chpasswd: { expire: False }
              packages:
                - nginx
              runcmd:
                - [ "systemctl", "enable", "--now", "nginx" ]
          name: cloudinitdisk
EOF
```

#### Expose the virtual machine with a typed `LoadBalancer` service 

When creating the `LoadBalancer` typed service, we need to remember annotating the address-pool we want to use 
`addresspool-sample1` and also add the selector `metallb-service: nginx`:

```yaml
cat <<EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: metallb-nginx-svc
  namespace: default
  annotations:
    metallb.universe.tf/address-pool: addresspool-sample1
spec:
  externalTrafficPolicy: Local
  ipFamilies:
    - IPv4
  ports:
    - name: tcp-5678
      protocol: TCP
      port: 5678
      targetPort: 80
  type: LoadBalancer
  selector:
    metallb-service: nginx
EOF
```

Notice that the service got assigned with an external IP from the range assigned by the address pool: 

```bash
kubectl get service -n default metallb-nginx-svc
```

Example output:
```bash
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
metallb-nginx-svc   LoadBalancer   10.96.254.136   172.18.1.1    5678:32438/TCP   53s
```

#### Access the virtual machine from outside the cluster

Finally, we can check that the nginx server is accessible from outside the cluster:
```bash
curl -s -o /dev/null 172.18.1.1:5678 && echo "URL exists"
```

Example output:
```bash
URL exists
```
Note that it may take a short while for the URL to work after setting the service.


## Doing this on your own cluster

Moving outside the demo example, one who would like use MetalLB on their real life cluster, should also take other considerations in mind:
- User privileges: you should have `cluster-admin` privileges on the cluster - in order to install MetalLB.
- IP Ranges for MetalLB: getting IP Address pools allocation for MetalLB depends on your cluster environment:
  - If you're running a bare-metal cluster in a shared host environment, you need to first reserve this IP Address pool from your hosting provider.
  - Alternatively, if you're running on a private cluster, you can use one of the private IP Address spaces (a.k.a RFC1918 addresses). Such addresses are free, and work fine as long as you’re only providing cluster services to your LAN.

## Conclusion

In this blog post we used MetalLB to expose a service using an external IP assigned to a virtual machine. 
This illustrates how virtual machine traffic can be load-balanced via a service.
