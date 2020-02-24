---
layout: post
author: jcpowermac
description: Quick rehash of the network deep-dive
navbar_active: Blogs
pub-date: Oct 11
pub-year: 2018
category: news
comments: true
tags: [networking, multus, ovs-cni, iptables]
---

# Introduction

This post is a quick rehash of the previous [post]({% post_url 2018-04-25-KubeVirt-Network-Deep-Dive %}) regarding KubeVirt networking.

It has been updated to reflect the updates that are included with v0.8.0 which includes
optional layer 2 support via Multus and the ovs-cni. I won't be covering the installation
of [OKD](https://docs.okd.io/), Kubernetes, KubeVirt, [Multus or ovs-cni]({% post_url 2018-09-12-attaching-to-multiple-networks %}) all can be found in other documentation or
posts.

# KubeVirt Virtual Machines

Like in the previous post I will deploy two virtual machines on two different hosts within an OKD cluster.
These instances are where we will install our simple NodeJS and MongoDB application.

## Create Objects and Start the Virtual Machines

One of the first objects to create is the `NetworkAttachmentDefinition`.
We are using a fairly simple definition for this post with an ovs bridge `br1` and no vlan configured.

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovs-net-br1
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "ovs",
    "bridge": "br1"
    }'
```

```sh
oc create -f https://gist.githubusercontent.com/jcpowermac/633de0066ee7990afc09fbd35ae776fe/raw/ac259386e1499b7f9c51316e4d5dcab152b60ce7/mongodb.yaml
oc create -f https://gist.githubusercontent.com/jcpowermac/633de0066ee7990afc09fbd35ae776fe/raw/ac259386e1499b7f9c51316e4d5dcab152b60ce7/nodejs.yaml
```

Start the virtual machines instances

```sh
~/virtctl start nodejs
~/virtctl start mongodb
```

Review KubeVirt virtual machine related objects

```sh
$ oc get net-attach-def
NAME          AGE
ovs-net-br1   16d

$ oc get vm
NAME      AGE
mongodb   4d
nodejs    4d

$ oc get vmi
NAME      AGE
mongodb   3h
nodejs    3h

$ oc get pod
NAME                          READY     STATUS    RESTARTS   AGE
virt-launcher-mongodb-bw2t8   2/2       Running   0          3h
virt-launcher-nodejs-dlgv6    2/2       Running   0          3h
```

## Service and Endpoints

We may still want to use services and routes with a KubeVirt virtual machine instance utilizing
multiple interfaces.

The service object below is considered
[headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
because the `clusterIP` is set to `None`. We don't want load-balancing or single service IP as
this would force traffic over the cluster network which in this example we are trying to avoid.

### Mongo

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: mongo
spec:
  clusterIP: None
  ports:
    - port: 27017
      targetPort: 27017
      name: mongo
      nodePort: 0
selector: {}
---
kind: Endpoints
apiVersion: v1
metadata:
  name: mongo
subsets:
  - addresses:
      - ip: 192.168.123.139
    ports:
      - port: 27017
        name: mongo
```

The above ip address is provided by DHCP via dnsmasq to the virtual machine instance's `eth1` interface.
All the nodes are virtual instances configured by libvirt.

After creating the service and endpoints objects lets confirm that DNS is resolving correctly.

```
$ ssh fedora@$(oc get pod -l kubevirt-vm=nodejs --template '{{ range .items }}{{.status.podIP}}{{end}}') \
"python3 -c \"import socket;print(socket.gethostbyname('mongo.vm.svc.cluster.local'))\""
192.168.123.139
```

### Node

We can also add a `service`, `endpoints` and `route` for the nodejs virtual machine so the application
is accessible from the defined subdomain.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node
spec:
  clusterIP: None
  ports:
    - name: node
      port: 8080
      protocol: TCP
      targetPort: 8080
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: node
subsets:
  - addresses:
      - ip: 192.168.123.140
    ports:
      - name: node
        port: 8080
        protocol: TCP
---
apiVersion: v1
kind: Route
metadata:
  name: node
spec:
  to:
    kind: Service
    name: node
```

## Testing our application

I am using the same application and method of installation as the previous post so I won't
duplicate it here. Just in case though let's make sure that the application is available
via the `route`.

`$ curl http://node-vm.apps.192.168.122.101.nip.io`

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <title>Welcome to OpenShift</title>
    ...outout...
    <p>
      Page view count:
      <span class="code" id="count-value">2</span>
      ...output...
    </p>
  </head>
</html>
```

# Networking in Detail

Just like in the previous post we should confirm how this works all together. Let's review the virtual machine to virtual machine
communication and route to virtual machine.

## Kubernetes-level

### services

We have created two headless services one for node and one for mongo.
This allows us to use the hostname mongo to connect to MongoDB via the alternative interface.

```
$ oc get services
NAME      TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)     AGE
mongo     ClusterIP   None         <none>        27017/TCP   8h
node      ClusterIP   None         <none>        8080/TCP    7h

$ ssh fedora@$(oc get pod virt-launcher-nodejs-dlgv6 --template '{{.status.podIP}}') cat /etc/sysconfig/nodejs
MONGO_URL=mongodb://nodejs:nodejspassword@mongo.vm.svc.cluster.local/nodejs
```

### endpoints

The endpoints below were manually created for each virtual machine based on the IP Address of `eth1`.

```
$ oc get endpoints
NAME      ENDPOINTS               AGE
mongo     192.168.123.139:27017   8h
node      192.168.123.140:8080    7h
```

### route

This will allow us access the NodeJS example application using the route url.

`$ oc get route`

```
NAME      HOST/PORT                             PATH      SERVICES   PORT      TERMINATION   WILDCARD
node      node-vm.apps.192.168.122.101.nip.io             node       <all>                   None
```

## Host-level

In addition to the existing interface `eth0` and bridge `br0`, `eth1` is the uplink for the ovs-cni bridge `br1`. This needs to be manually configured prior to use.

### interfaces

`ip a`

```
...output...
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:5f:90:85 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.111/24 brd 192.168.122.255 scope global noprefixroute dynamic eth0
       valid_lft 2282sec preferred_lft 2282sec
    inet6 fe80::5054:ff:fe5f:9085/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master ovs-system state UP group default qlen 1000
    link/ether 52:54:01:5f:90:85 brd ff:ff:ff:ff:ff:ff
...output...
5: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 2a:6e:65:7e:65:3a brd ff:ff:ff:ff:ff:ff
9: br1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 6e:d5:db:12:b5:43 brd ff:ff:ff:ff:ff:ff
10: br0: <BROADCAST,MULTICAST> mtu 1450 qdisc noop state DOWN group default qlen 1000
    link/ether aa:3c:bd:5a:ac:46 brd ff:ff:ff:ff:ff:ff
...output...
```

### Bridge

The command and output below shows the Open vSwitch bridge and interfaces. The `veth8bf25a9b` interface
is one of the veth pair created to connect the virtual machine to the Open vSwitch bridge.

`ovs-vsctl show`

```
77147900-3d26-46c6-ac0b-755da3aa4b97
    Bridge "br1"
        Port "br1"
            Interface "br1"
                type: internal
        Port "veth8bf25a9b"
            Interface "veth8bf25a9b"
        Port "eth1"
            Interface "eth1"
...output...
```

## Pod-level

### interfaces

There are two bridges `k6t-eth0` and `k6t-net0`. `eth0` and `net1` are a veth pair with the alternate side
available on the host. `eth0` is a member of the `k6t-eth0` bridge. `net1` is a member of the `k6t-net0` bridge.

`~ oc exec -n vm -c compute virt-launcher-nodejs-76xk7 -- ip a`

```
...output
3: eth0@if41: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master k6t-eth0 state UP group default
    link/ether 0a:58:0a:17:79:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::858:aff:fe17:7904/64 scope link
       valid_lft forever preferred_lft forever
5: net1@if42: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master k6t-net1 state UP group default
    link/ether 02:00:00:74:17:75 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::ff:fe74:1775/64 scope link
       valid_lft forever preferred_lft forever
6: k6t-eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    link/ether 0a:58:0a:17:79:04 brd ff:ff:ff:ff:ff:ff
    inet 169.254.75.10/32 brd 169.254.75.10 scope global k6t-eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::858:aff:fe82:21/64 scope link
       valid_lft forever preferred_lft forever
7: k6t-net1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:00:00:74:17:75 brd ff:ff:ff:ff:ff:ff
    inet 169.254.75.11/32 brd 169.254.75.11 scope global k6t-net1
       valid_lft forever preferred_lft forever
    inet6 fe80::ff:fe07:2182/64 scope link dadfailed tentative
       valid_lft forever preferred_lft forever
8: vnet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc pfifo_fast master k6t-eth0 state UNKNOWN group default qlen 1000
    link/ether fe:58:0a:82:00:21 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::fc58:aff:fe82:21/64 scope link
       valid_lft forever preferred_lft forever
9: vnet1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master k6t-net1 state UNKNOWN group default qlen 1000
    link/ether fe:37:cf:e0:ad:f2 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::fc37:cfff:fee0:adf2/64 scope link
       valid_lft forever preferred_lft forever
```

Showing the bridge `k6t-eth0` and `k6t-net` member ports.

`~ oc exec -n vm -c compute virt-launcher-nodejs-dlgv6 -- bridge link show`

```
3: eth0 state UP @if41: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 master k6t-eth0 state forwarding priority 32 cost 2
5: net1 state UP @if42: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master k6t-net1 state forwarding priority 32 cost 2
8: vnet0 state UNKNOWN : <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 master k6t-eth0 state forwarding priority 32 cost 100
9: vnet1 state UNKNOWN : <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master k6t-net1 state forwarding priority 32 cost 100
```

### DHCP

The virtual machine network is configured by DHCP. You can see `virt-launcher` has UDP port 67 open
on the `k6t-eth0` interface to serve DHCP to the virtual machine. As described in the previous
[post]({% post_url 2018-04-25-KubeVirt-Network-Deep-Dive %}) the `virt-launcher` process contains
a simple DHCP server that provides an offer and typical options to the virtual machine instance.

`~ oc exec -n vm -c compute virt-launcher-nodejs-dlgv6 -- ss -tuanp`

```
Netid State   Recv-Q   Send-Q         Local Address:Port     Peer Address:Port
udp   UNCONN  0        0           0.0.0.0%k6t-eth0:67            0.0.0.0:*      users:(("virt-launcher",pid=7,fd=15))
```

### libvirt

With `virsh domiflist` we can also see that the `vnet0` interface is a member on the `k6t-eth0` bridge and `vnet1` is a member of the k6t-net1 bridge.

`~ oc exec -n vm -c compute virt-launcher-nodejs-dlgv6 -- virsh domiflist vm_nodejs`

```
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet0      bridge     k6t-eth0   virtio      0a:58:0a:82:00:2a
vnet1      bridge     k6t-net1   virtio      20:37:cf:e0:ad:f2
```

## VM-level

### interfaces

Fortunately the vm interfaces are fairly typical. Two interfaces: one that has been assigned the original
pod ip address and the other the `ovs-cni` layer 2 interface. The `eth1` interface receives a IP address
from DHCP provided by dnsmasq that was configured by libvirt network on the physical host.

`~ ssh fedora@$(oc get pod virt-launcher-nodejs-dlgv6 --template '{{.status.podIP}}') sudo ip a`

```
...output...
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc fq_codel state UP group default qlen 1000
    link/ether 0a:58:0a:82:00:2a brd ff:ff:ff:ff:ff:ff
    inet 10.130.0.42/23 brd 10.130.1.255 scope global dynamic eth0
       valid_lft 86239518sec preferred_lft 86239518sec
    inet6 fe80::858:aff:fe82:2a/64 scope link tentative dadfailed
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 20:37:cf:e0:ad:f2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.123.140/24 brd 192.168.123.255 scope global dynamic eth1
       valid_lft 3106sec preferred_lft 3106sec
    inet6 fe80::2237:cfff:fee0:adf2/64 scope link
       valid_lft forever preferred_lft forever
```

#### Configuration and DNS

In this example we want to use Kubernetes services so special care must be used when
configuring the network interfaces. The default route and dns configuration must be
maintained by `eth0`. `eth1` has both route and dns configuration disabled.

`~ ssh fedora@$(oc get pod virt-launcher-nodejs-dlgv6 --template '{{.status.podIP}}') sudo cat /etc/sysconfig/network-scripts/ifcfg-eth0`

```
BOOTPROTO=dhcp
DEVICE=eth0
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
# Use route and dns from DHCP
DEFROUTE=yes
PEERDNS=yes
```

`~ ssh fedora@$(oc get pod virt-launcher-nodejs-dlgv6 --template '{{.status.podIP}}') sudo cat /etc/sysconfig/network-scripts/ifcfg-eth1`

```
BOOTPROTO=dhcp
DEVICE=eth1
IPV6INIT=no
NM_CONTROLLED=no
ONBOOT=yes
TYPE=Ethernet
# Do not use route and dns from DHCP
PEERDNS=no
DEFROUTE=no
```

Just quickly wanted to cat the `/etc/resolv.conf` file to show that DNS is configured so that kube-dns will be properly queried.

`~ ssh fedora@$(oc get pod virt-launcher-nodejs-76xk7 --template '{{.status.podIP}}') sudo cat /etc/resolv.conf`

```
search vm.svc.cluster.local. svc.cluster.local. cluster.local. 168.122.112.nip.io.
nameserver 192.168.122.112
```

## VM to VM communication

The virtual machines are on different hosts. This was done purposely to show that connectivity
between virtual machine and hosts. Here we finally get to use [Skydive](https://github.com/skydive-project/skydive).
The real-time topology below along with
arrows annotate the flow of packets between the host and virtual machine network devices.

<div class="my-gallery" itemscope itemtype="http://schema.org/ImageGallery">
    <figure itemprop="associatedMedia" itemscope itemtype="http://schema.org/ImageObject">
        <a href="/assets/images/skydive_vm_to_vm.png" itemprop="contentUrl" data-size="1601x589">
            <img src="/assets/images/skydive_vm_to_vm.png" width="600" height="220" itemprop="thumbnail" alt="VM to VM" />
        </a>
        <figcaption itemprop="caption description">VM to VM</figcaption>
    </figure>
</div>

### Connectivity Tests

To confirm connectivity we are going to do a few things. First look for an established
connection to MongoDB and finally check the NodeJS logs looking for confirmation of database connection.

#### TCP connection

After connecting to the nodejs virtual machine via ssh we can use `ss` to determine the current TCP connections.
We are specifically looking for the established connections to the MongoDB service that is running on the mongodb virtual machine.

`ssh fedora@$(oc get pod virt-launcher-nodejs-dlgv6 --template '{{.status.podIP}}') sudo ss -tanp`

```
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port
...output...
ESTAB      0      0      192.168.123.140:33156              192.168.123.139:27017               users:(("node",pid=12893,fd=11))
ESTAB      0      0      192.168.123.140:33162              192.168.123.139:27017               users:(("node",pid=12893,fd=13))
ESTAB      0      0      192.168.123.140:33164              192.168.123.139:27017               users:(("node",pid=12893,fd=14))
...output...
```

#### Logs

Here we are reviewing the logs of node to confirm we have a database connection to mongo via the service hostname.

`ssh fedora@$(oc get pod virt-launcher-nodejs-dlgv6 --template '{{.status.podIP}}') sudo journalctl -u nodejs`

```
...output...
Oct 01 18:28:09 nodejs.localdomain systemd[1]: Started OpenShift NodeJS Example.
Oct 01 18:28:10 nodejs.localdomain node[12893]: Server running on http://0.0.0.0:8080
Oct 01 18:28:10 nodejs.localdomain node[12893]: Connected to MongoDB at: mongodb://nodejs:nodejspassword@mongo.vm.svc.cluster.local/nodejs
...output...
```

## Route to VM communication

Finally let's confirm that when using the OKD route that traffic is successfully routed to nodejs eth1 interface.

### HAProxy Traffic Status

OKD HAProxy provides optional traffic status - which we already enabled. The screenshot below shows
the requests that Nginx is receiving for `nodejs.ingress.virtomation.com`.

<div class="my-gallery" itemscope itemtype="http://schema.org/ImageGallery">
    <figure itemprop="associatedMedia" itemscope itemtype="http://schema.org/ImageObject">
        <a href="/assets/images/haproxy_stats.png" itemprop="contentUrl" data-size="1642x449">
            <img src="/assets/images/haproxy_stats.png" width="600" height="220" itemprop="thumbnail" alt="haproxy-stats" />
        </a>
        <figcaption itemprop="caption description">haproxy-stats</figcaption>
    </figure>
</div>

### HAProxy to NodeJS VM

The HAProxy pod runs on the master OKD in this scenario. Using [skydive](https://github.com/skydive-project/skydive) we can see a TCP 8080 connection to nodejs eth1 interface exiting eth1 of the master.

`$ oc get pod -o wide -n default -l router=router`

```
NAME             READY     STATUS    RESTARTS   AGE       IP                NODE                     NOMINATED NODE
router-2-nfqr4   0/1       Running   0          20h       192.168.122.101   192.168.122.101.nip.io   <none>
```

<div class="my-gallery" itemscope itemtype="http://schema.org/ImageGallery">
    <figure itemprop="associatedMedia" itemscope itemtype="http://schema.org/ImageObject">
        <a href="/assets/images/skydive_haproxy_to_vm.png" itemprop="contentUrl" data-size="1601x438">
            <img src="/assets/images/skydive_haproxy_to_vm.png" width="600" height="220" itemprop="thumbnail" alt="haproxy-vm" />
        </a>
        <figcaption itemprop="caption description">haproxy-vm</figcaption>
    </figure>
</div>
