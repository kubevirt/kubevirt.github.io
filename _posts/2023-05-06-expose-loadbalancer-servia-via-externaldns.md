---
layout: post
author: Miguel Duarte Barroso
title: Making Kubernetes LoadBalancer service discoverable via DNS
description: This post explains how to configure discovery of LoadBalancer service types via DNS.
navbar_active: Blogs
pub-date: May 05
pub-year: 2023
category: news
tags:
  [
    "Kubevirt",
    "kubernetes",
    "virtual machine",
    "VM",
    "DNS",
    "LoadBalancer"
  ]
comments: true
---

## Introduction
In the past we've seen how [MetalLB](https://metallb.universe.tf/) can be used
to provide fault-tolerant access to an application on virtual machines through
an external IP address.

This blog post wants to take this a step further, and allow the user to
interact with exposed services via FQDN, rather than IPs.

## Motivation
TODO

## Demo
This post assumes the user has followed throught the installation instructions
available in the
[MetalLB KubeVirt blog post](https://kubevirt.io/2022/Virtual-Machines-with-MetalLB.html),
and as a result already has `MetalLB` installed in the cluster.

### Architecture
Please refer to the architecture diagram below to understand the solution.
![MetalLB Service resolved by name](/assets/2023-05-08-metallb-external-dns/arch.jpg)

1. Client outside the Cluster initiates the ssh connection
2. Cluster interface used by MetalLB to propagate the IPs of MetalLB
3. Service Object to be configured by annotations to receive an IP of MetalLB
   and the A record to be set by the `externalDNS` pod.
4. Virtual Machine receives the ssh connection
5. MetalLB Deployment including L2Advertisment and IPAddressPool
6. `externalDNS` Deployment to dynamiclly update the DNS Server
7. BIND DNS Server outside the Cluster holding the zone for the eomain `ocponbm.infra-as-code.org`

### Configuring MetalLB
1. Provision the MetalLB CR:
```yaml
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
```

2. Define `IpAddresspool` for desired IP range
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  namespace: metallb-system
  name: kubevirt-example-01
spec:
  addresses:
  - 10.17.9.150 - 10.17.9.250
```

3. Configure the layer2 advertisement configuration
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
   - kubevirt-example-01
```

4. Create `Loadbalancer` service referencing the IPAddressPool
```yaml
kind: Service
apiVersion: v1
metadata:
  name: rhel8-metallb-ssh-svc
  namespace: kubevirt-tako
  annotations:
    metallb.universe.tf/address-pool: kubevirt-example-01 # point this to your address pool
spec:
  externalTrafficPolicy: Local
  ipFamilies:
    - IPv4
  ports:
    - name: tcp-22
      protocol: TCP
      port: 22
      targetPort: 22
  type: LoadBalancer
  selector:
    kubevirt.io/domain: rhel8-demo
```

### Configuring the DNS server
TODO

### Synchronize exposed services with DNS servers
TODO

## Conclusion
TODO

