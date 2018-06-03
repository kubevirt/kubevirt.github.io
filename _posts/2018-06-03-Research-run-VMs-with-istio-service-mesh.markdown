---
layout: post
author: SchSeba
description: In this post we will deploy a vm on top of kubernetes with istio service mesh
---

# Introduction
In this blog post we are going to talk about istio and virtual machines on top of kubernetes.

Little explanation about Istio from there page

## Istio Overview
This document introduces Istio: an open platform to connect, manage, and secure microservices. Istio provides an easy way to create a network of deployed services with load balancing, service-to-service authentication, monitoring, and more, without requiring any changes in service code. You add Istio support to services by deploying a special sidecar proxy throughout your environment that intercepts all network communication between microservices, configured and managed using Istio’s control plane functionality.

### Why use Istio?
Istio addresses many of the challenges faced by developers and operators as monolithic applications transition towards a distributed microservice architecture. The term service mesh is often used to describe the network of microservices that make up such applications and the interactions between them. As a service mesh grows in size and complexity, it can become harder to understand and manage. Its requirements can include discovery, load balancing, failure recovery, metrics, and monitoring, and often more complex operational requirements such as A/B testing, canary releases, rate limiting, access control, and end-to-end authentication.

* Istio provides a complete solution to satisfy the diverse requirements of microservice applications by providing behavioral insights and operational control over the service mesh as a whole. It provides a number of key capabilities uniformly across a network of services:

* Traffic Management. Control the flow of traffic and API calls between services, make calls more reliable, and make the network more robust in the face of adverse conditions.

* Service Identity and Security. Provide services in the mesh with a verifiable identity and provide the ability to protect service traffic as it flows over networks of varying degrees of trustability.

* Policy Enforcement. Apply organizational policy to the interaction between services, ensure access policies are enforced and resources are fairly distributed among consumers. Policy changes are made by configuring the mesh, not by changing application code.

* Telemetry. Gain understanding of the dependencies between services and the nature and flow of traffic between them, providing the ability to quickly identify issues.

In addition to these behaviors, Istio is designed for extensibility to meet diverse deployment needs:

Platform Support. Istio is designed to run in a variety of environments including ones that span Cloud, on-premise, Kubernetes, Mesos etc. We’re initially focused on Kubernetes but are working to support other environments soon.

Integration and Customization. The policy enforcement component can be extended and customized to integrate with existing solutions for ACLs, logging, monitoring, quotas, auditing and more.

These capabilities greatly decrease the coupling between application code, the underlying platform, and policy. This decreased coupling not only makes services easier to implement, but also makes it simpler for operators to move application deployments between environments or to new policy schemes. Applications become inherently more portable as a result.

### Istio Architecture
An Istio service mesh is logically split into a data plane and a control plane.

The data plane is composed of a set of intelligent proxies (Envoy) deployed as sidecars that mediate and control all network communication between microservices, along with a general-purpose policy and telemetry hub (Mixer).

The control plane is responsible for managing and configuring proxies to route traffic, and configuring Mixers to enforce policies and collect telemetry.

The following diagram shows the different components that make up each plane:

<img src="../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/arch.svg" alt="Istio-Architecture" style="width: 800px;"/>

### Envoy
Istio uses an extended version of the Envoy proxy, a high-performance proxy developed in C++, to mediate all inbound and outbound traffic for all services in the service mesh. Istio leverages Envoy’s many built-in features such as dynamic service discovery, load balancing, TLS termination, HTTP/2 & gRPC proxying, circuit breakers, health checks, staged rollouts with %-based traffic split, fault injection, and rich metrics.

Envoy is deployed as a sidecar to the relevant service in the same Kubernetes pod. This allows Istio to extract a wealth of signals about traffic behavior as attributes, which in turn it can use in Mixer to enforce policy decisions, and be sent to monitoring systems to provide information about the behavior of the entire mesh. The sidecar proxy model also allows you to add Istio capabilities to an existing deployment with no need to rearchitect or rewrite code. You can read more about why we chose this approach in our Design Goals.

### Mixer
Mixer is a platform-independent component responsible for enforcing access control and usage policies across the service mesh and collecting telemetry data from the Envoy proxy and other services. The proxy extracts request level attributes, which are sent to Mixer for evaluation. More information on this attribute extraction and policy evaluation can be found in Mixer Configuration. Mixer includes a flexible plugin model enabling it to interface with a variety of host environments and infrastructure backends, abstracting the Envoy proxy and Istio-managed services from these details.

### Pilot
Pilot provides service discovery for the Envoy sidecars, traffic management capabilities for intelligent routing (e.g., A/B tests, canary deployments, etc.), and resiliency (timeouts, retries, circuit breakers, etc.). It converts high level routing rules that control traffic behavior into Envoy-specific configurations, and propagates them to the sidecars at runtime. Pilot abstracts platform-specific service discovery mechanisms and synthesizes them into a standard format consumable by any sidecar that conforms to the Envoy data plane APIs. This loose coupling allows Istio to run on multiple environments (e.g., Kubernetes, Consul/Nomad) while maintaining the same operator interface for traffic management.

### Citadel
Citadel provides strong service-to-service and end-user authentication, with built-in identity and credential management. It can be used to upgrade unencrypted traffic in the service mesh, and provides operators the ability to enforce policy based on service identity rather than network controls. Starting from release 0.5, Istio supports role-based access control to control who can access your services.


# Libvirt
<img src="../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/libvirt-logo-banner.png" alt="libvirt-logo" style="width: 300px;"/>

Libvirt is collection of software that provides a convenient way to manage virtual machines and other virtualization functionality, such as storage and network interface management. These software pieces include a long term stable C API, a daemon (libvirtd), and a command line utility (virsh). A primary goal of libvirt is to provide a single way to manage multiple different virtualization providers/hypervisors, such as the KVM/QEMU, Xen, LXC, OpenVZ or VirtualBox hypervisors (among others).

Some of the major libvirt features are:

VM management: Various domain lifecycle operations such as start, stop, pause, save, restore, and migrate. Hotplug operations for many device types including disk and network interfaces, memory, and CPUs.
Remote machine support: All libvirt functionality is accessible on any machine running the libvirt daemon, including remote machines. A variety of network transports are supported for connecting remotely, with the simplest being SSH, which requires no extra explicit configuration.
Storage management: Any host running the libvirt daemon can be used to manage various types of storage: create file images of various formats (qcow2, vmdk, raw, ...), mount NFS shares, enumerate existing LVM volume groups, create new LVM volume groups and logical volumes, partition raw disk devices, mount iSCSI shares, and much more.
Network interface management: Any host running the libvirt daemon can be used to manage physical and logical network interfaces. Enumerate existing interfaces, as well as configure (and create) interfaces, bridges, vlans, and bond devices.
Virtual NAT and Route based networking: Any host running the libvirt daemon can manage and create virtual networks. Libvirt virtual networks use firewall rules to act as a router, providing VMs transparent access to the host machines network.

# About KVM
<img src="../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/kvmbanner-logo3.png" alt="kvm-logo" style="width: 300px;"/>

KVM (for Kernel-based Virtual Machine) is a full virtualization solution for Linux on x86 hardware containing virtualization extensions (Intel VT or AMD-V). It consists of a loadable kernel module, kvm.ko, that provides the core virtualization infrastructure and a processor specific module, kvm-intel.ko or kvm-amd.ko.

Using KVM, one can run multiple virtual machines running unmodified Linux or Windows images. Each virtual machine has private virtualized hardware: a network card, disk, graphics adapter, etc.

KVM is open source software. The kernel component of KVM is included in mainline Linux, as of 2.6.20. The userspace component of KVM is included in mainline QEMU, as of 1.3.

# About iptables
iptables is a user-space utility program that allows a system administrator to configure the tables provided by the Linux kernel firewall (implemented as different Netfilter modules) and the chains and rules it stores. Different kernel modules and programs are currently used for different protocols; iptables applies to IPv4, ip6tables to IPv6

Xtables allows the system administrator to define tables containing chains of rules for the treatment of packets. Each table is associated with a different kind of packet processing. Packets are processed by sequentially traversing the rules in chains. A rule in a chain can cause a goto or jump to another chain, and this can be repeated to whatever level of nesting is desired. (A jump is like a “call”, i.e. the point that was jumped from is remembered.) Every network packet arriving at or leaving from the computer traverses at least one chain.


Packet flow paths. Packets start at a given box and will flow along a certain path, depending on the circumstances.
The origin of the packet determines which chain it traverses initially. There are five predefined chains (mapping to the five available Netfilter hooks), though a table may not have all chains. Predefined chains have a policy, for example DROP, which is applied to the packet if it reaches the end of the chain. The system administrator can create as many other chains as desired. These chains have no policy; if a packet reaches the end of the chain it is returned to the chain which called it. A chain may be empty.

PREROUTING: Packets will enter this chain before a routing decision is made.

INPUT: Packet is going to be locally delivered. It does not have anything to do with processes having an opened socket; local delivery is controlled by the "local-delivery" routing table: ip route show table local.

FORWARD: All packets that have been routed and were not for local delivery will traverse this chain.

OUTPUT: Packets sent from the machine itself will be visiting this chain.

POSTROUTING: Routing decision has been made. Packets enter this chain just before handing them off to the hardware.

Each rule in a chain contains the specification of which packets it matches. It may also contain a target (used for extensions) or verdict (one of the built-in decisions). As a packet traverses a chain, each rule in turn is examined. If a rule does not match the packet, the packet is passed to the next rule. If a rule does match the packet, the rule takes the action indicated by the target/verdict, which may result in the packet being allowed to continue along the chain or it may not. Matches make up the large part of rulesets, as they contain the conditions packets are tested for. These can happen for about any layer in the OSI model, as with e.g. the --mac-source and -p tcp --dport parameters, and there are also protocol-independent matches, such as -m time.

The packet continues to traverse the chain until either

a rule matches the packet and decides the ultimate fate of the packet, for example by calling one of the ACCEPT or DROP, or a module returning such an ultimate fate; or
a rule calls the RETURN verdict, in which case processing returns to the calling chain; or
the end of the chain is reached; traversal either continues in the parent chain (as if RETURN was used), or the base chain policy, which is an ultimate fate, is used.
Targets also return a verdict like ACCEPT (NAT modules will do this) or DROP (e.g. the REJECT module), but may also imply CONTINUE (e.g. the LOG module; CONTINUE is an internal name) to continue with the next rule as if no target/verdict was specified at all.

![Iptables](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/iptables.png)

# About ebtables
The ebtables program is a filtering tool for a Linux-based bridging firewall. It enables transparent filtering of network traffic passing through a Linux bridge. The filtering possibilities are limited to link layer filtering and some basic filtering on higher network layers. Advanced logging, MAC DNAT/SNAT and brouter facilities are also included.

The ebtables tool can be combined with the other Linux filtering tools (iptables, ip6tables and arptables) to make a bridging firewall that is also capable of filtering these higher network layers. This is enabled through the bridge-netfilter architecture which is a part of the standard Linux kernel.

To use ebtables the relevant module kernels need to be loaded, the follow command will load them into the kernel
```
 modprobe bridge
```

# About Tproxy
Work on linux machines only!

Transparent Proxy (TProxy for short) provides the ability to transparently proxy traffic through a userland program without the need for conntrack overhead caused by using NAT to force the traffic into the proxy.

Another feature of TProxy is the ability to connect to remote hosts using the same client information as the original client making the connection. For example, if the connection 10.0.0.1:50073 -> 8.8.8.8:80 was intercepted, the service could make a connection to 8.8.8.8:80 pretending to come from 10.0.0.1:50073.

The linux kernel and IPTables handle diverting the packets back into the proxy for those remote connections by matching incoming packets to any locally bound sockets with the same details.


# Research explanation
Our research goal was to gave virtual machines running inside pods (kubevirt project) all the benefits kubernetes have to offer, one of them is a service mesh like istio.

## Iptables only with dnat and source nat configuration
<span style="color:red;">This configuration is istio only!</span>

For this solution a created the following architecture

![Iptables-Diagram](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/Iptables-diagram.png)

With the follow yaml configuration

```
apiVersion: v1
kind: Service
metadata:
  name: application-devel
  labels:
    app: libvirtd-devel
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: libvirtd-devel

---
apiVersion: v1
kind: Service
metadata:
  name: libvirtd-client-devel
  labels:
    app: libvirtd-devel
spec:
  ports:
  - port: 16509
    name: client-connection
  - port: 5900
    name: spice
  - port: 22
    name: ssh
  selector:
    app: libvirtd-devel
  type: LoadBalancer
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  creationTimestamp: null
  name: libvirtd-devel
spec:
  replicas: 1
  strategy: {}
  template:
    metadata:
      annotations:
        sidecar.istio.io/status: '{"version":"43466efda2266e066fb5ad36f2d1658de02fc9411f6db00ccff561300a2a3c78","initContainers":["istio-init","enable-core-dump"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-certs"]}'
      creationTimestamp: null
      labels:
        app: libvirtd-devel
    spec:
      containers:
      - image: docker.io/sebassch/mylibvirtd:devel
        imagePullPolicy: Always
        name: compute
        ports:
        - containerPort: 9080
        - containerPort: 16509
        - containerPort: 5900
        - containerPort: 22
        securityContext:
          capabilities:
            add:
            - ALL
          privileged: true
          runAsUser: 0
        volumeMounts:
          - mountPath: /var/lib/libvirt/images
            name: test-volume
          - mountPath: /host-dev
            name: host-dev
          - mountPath: /host-sys
            name: host-sys
        resources: {}
        env:
          - name: LIBVIRTD_DEFAULT_NETWORK_DEVICE
            value: "eth0"
      - args:
        - proxy
        - sidecar
        - --configPath
        - /etc/istio/proxy
        - --binaryPath
        - /usr/local/bin/envoy
        - --serviceCluster
        - productpage
        - --drainDuration
        - 45s
        - --parentShutdownDuration
        - 1m0s
        - --discoveryAddress
        - istio-pilot.istio-system:15005
        - --discoveryRefreshDelay
        - 1s
        - --zipkinAddress
        - zipkin.istio-system:9411
        - --connectTimeout
        - 10s
        - --statsdUdpAddress
        - istio-mixer.istio-system:9125
        - --proxyAdminPort
        - "15000"
        - --controlPlaneAuthPolicy
        - MUTUAL_TLS
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: INSTANCE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        image: docker.io/istio/proxy:0.7.1
        imagePullPolicy: IfNotPresent
        name: istio-proxy
        resources: {}
        securityContext:
          privileged: false
          readOnlyRootFilesystem: true
          runAsUser: 1337
        volumeMounts:
        - mountPath: /etc/istio/proxy
          name: istio-envoy
        - mountPath: /etc/certs/
          name: istio-certs
          readOnly: true
      initContainers:
      - args:
        - -p
        - "15001"
        - -u
        - "1337"
        image: docker.io/istio/proxy_init:0.7.1
        imagePullPolicy: IfNotPresent
        name: istio-init
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
      - args:
        - -c
        - sysctl -w kernel.core_pattern=/etc/istio/proxy/core.%e.%p.%t && ulimit -c
          unlimited
        command:
        - /bin/sh
        image: alpine
        imagePullPolicy: IfNotPresent
        name: enable-core-dump
        resources: {}
        securityContext:
          privileged: true
      volumes:
      - emptyDir:
          medium: Memory
        name: istio-envoy
      - name: istio-certs
        secret:
          optional: true
          secretName: istio.default
      - name: host-dev
        hostPath:
          path: /dev
          type: Directory
      - name: host-sys
        hostPath:
          path: /sys
          type: Directory
      - name: test-volume
        hostPath:
          # directory location on host
          path: /bricks/brick1/volume/Images
          # this field is optional
          type: Directory
status: {}

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: gateway-devel
  annotations:
    kubernetes.io/ingress.class: "istio"
spec:
  rules:
  - http:
      paths:
      - path: /devel-myvm
        backend:
          serviceName: application-devel
          servicePort: 9080
```

When the my-libvirt container start it run an entry point script for iptables configuration.

```
1. iptables -t nat -D PREROUTING 1
2. iptables -t nat -A PREROUTING -p tcp -m comment --comment "Kubevirt Spice"  --dport 5900 -j ACCEPT 
3. iptables -t nat -A PREROUTING -p tcp -m comment --comment "Kubevirt virt-manager"  --dport 16509 -j ACCEPT
4. iptables -t nat  -A PREROUTING -d 10.96.0.0/12 -m comment --comment "istio/redirect-ip-range-10.96.0.0/12-service cidr" -j ISTIO_REDIRECT
5. iptables -t nat  -A PREROUTING -d 192.168.0.0/16 -m comment --comment "istio/redirect-ip-range-192.168.0.0/16-Pod cidr" -j ISTIO_REDIRECT
6. iptables -t nat  -A OUTPUT -d 127.0.0.1/32 -p tcp -m comment --comment "Kubevirt mesh application port" --dport 9080 -j DNAT --to-destination 10.0.0.2
7. iptables -t nat  -A POSTROUTING -s 127.0.0.1/32 -d 10.0.0.2/32 -m comment --comment "Kubevirt VM Forward" -j SNAT --to-source `ifconfig eth0 | grep inet | awk '{print $2}'
```

Now lets explain every one of this lines:

1. Remove istio ingress connection rule that send all the ingress traffic directly to the envoy proxy (our vm traffic is ingress traffic for our pod)
2. Allow ingress connection with spice port to get our libvirt process running in the pod
3. Allow ingress connection with virt-manager port to get our libvirt process running in the pod
4. Redirect all the traffic that came from the k8s clusters services to the envoy process
5. Redirect all the traffic that came from the k8s clusters pods to the envoy process
6. Send all the traffic that came from envoy process to our vm by changing the destination ip address to ur vm ip address
7. Change the source ip address of the packet send by envoy from localhost to the pod ip address so the virtual machine can return the connection


### Iptables configuration conclusions
With this configuration all the traffic that exit the virtual machine to a k8s service will pass the envoy process and will enter the istio service mash.
Also all the traffic that came into the pod will be pass to envoy and after that it will be send to our virtual machine

Egress data flow in this solution:

![iptables-egress-traffic](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/iptables-egress.png)

Ingress data flow in this solution:

![iptables-ingress-traffic](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/iptables-ingress.png)

Pros:
* No external modules needed
* No external process needed
* All the traffic is handled by the kernel user space not involved

Cons:
* <span style="color:red;">Istio dedicated solution!</span>
* Not other process can change the iptables rules


## Iptables with a nat-proxy process
For this solution a created the following architecture

![nat-proxy-Diagram](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/nat-proxy.png)

With the follow yaml configuration
```
apiVersion: v1
kind: Service
metadata:
  name: application-nat-proxt
  labels:
    app: libvirtd-nat-proxt
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: libvirtd-nat-proxt
  type: LoadBalancer

---
apiVersion: v1
kind: Service
metadata:
  name: libvirtd-client-nat-proxt
  labels:
    app: libvirtd-nat-proxt
spec:
  ports:
  - port: 16509
    name: client-connection
  - port: 5900
    name: spice
  - port: 22
    name: ssh
  selector:
    app: libvirtd-nat-proxt
  type: LoadBalancer
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  creationTimestamp: null
  name: libvirtd-nat-proxt
spec:
  replicas: 1
  strategy: {}
  template:
    metadata:
      annotations:
        sidecar.istio.io/status: '{"version":"43466efda2266e066fb5ad36f2d1658de02fc9411f6db00ccff561300a2a3c78","initContainers":["istio-init","enable-core-dump"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-certs"]}'
      creationTimestamp: null
      labels:
        app: libvirtd-nat-proxt
    spec:
      containers:
      - image: docker.io/sebassch/mylibvirtd:devel
        imagePullPolicy: Always
        name: compute
        ports:
        - containerPort: 9080
        - containerPort: 16509
        - containerPort: 5900
        - containerPort: 22
        securityContext:
          capabilities:
            add:
            - ALL
          privileged: true
          runAsUser: 0
        volumeMounts:
          - mountPath: /var/lib/libvirt/images
            name: test-volume
          - mountPath: /host-dev
            name: host-dev
          - mountPath: /host-sys
            name: host-sys
        resources: {}
        env:
          - name: LIBVIRTD_DEFAULT_NETWORK_DEVICE
            value: "eth0"
      - image: docker.io/sebassch/mynatproxy:devel
        imagePullPolicy: Always
        name: proxy
        resources: {}
        securityContext:
          privileged: true
          capabilities:
            add:
            - NET_ADMIN
      - args:
        - proxy
        - sidecar
        - --configPath
        - /etc/istio/proxy
        - --binaryPath
        - /usr/local/bin/envoy
        - --serviceCluster
        - productpage
        - --drainDuration
        - 45s
        - --parentShutdownDuration
        - 1m0s
        - --discoveryAddress
        - istio-pilot.istio-system:15005
        - --discoveryRefreshDelay
        - 1s
        - --zipkinAddress
        - zipkin.istio-system:9411
        - --connectTimeout
        - 10s
        - --statsdUdpAddress
        - istio-mixer.istio-system:9125
        - --proxyAdminPort
        - "15000"
        - --controlPlaneAuthPolicy
        - MUTUAL_TLS
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: INSTANCE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        image: docker.io/istio/proxy:0.7.1
        imagePullPolicy: IfNotPresent
        name: istio-proxy
        resources: {}
        securityContext:
          privileged: false
          readOnlyRootFilesystem: true
          runAsUser: 1337
        volumeMounts:
        - mountPath: /etc/istio/proxy
          name: istio-envoy
        - mountPath: /etc/certs/
          name: istio-certs
          readOnly: true
      initContainers:
      - args:
        - -p
        - "15001"
        - -u
        - "1337"
        - -i
        - 10.96.0.0/12,192.168.0.0/16
        image: docker.io/istio/proxy_init:0.7.1
        imagePullPolicy: IfNotPresent
        name: istio-init
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
      - args:
        - -c
        - sysctl -w kernel.core_pattern=/etc/istio/proxy/core.%e.%p.%t && ulimit -c
          unlimited
        command:
        - /bin/sh
        image: alpine
        imagePullPolicy: IfNotPresent
        name: enable-core-dump
        resources: {}
        securityContext:
          privileged: true
      volumes:
      - emptyDir:
          medium: Memory
        name: istio-envoy
      - name: istio-certs
        secret:
          optional: true
          secretName: istio.default
      - name: host-dev
        hostPath:
          path: /dev
          type: Directory
      - name: host-sys
        hostPath:
          path: /sys
          type: Directory
      - name: test-volume
        hostPath:
          # directory location on host
          path: /bricks/brick1/volume/Images
          # this field is optional
          type: Directory
status: {}

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: gateway-nat-proxt
  annotations:
    kubernetes.io/ingress.class: "istio"
spec:
  rules:
  - http:
      paths:
      - path: /nat-proxt-myvm
        backend:
          serviceName: application-nat-proxt
          servicePort: 9080
```

When the mynatproxy container start it run an entry point script for iptables configuration.

```
1. iptables -t nat -I PREROUTING 1 -p tcp -s 10.0.1.2 -m comment --comment "nat-proxy redirect" -j REDIRECT --to-ports 8080
2. iptables -t nat -I OUTPUT 1 -p tcp -s 10.0.1.2 -j ACCEPT
3. iptables -t nat -I POSTROUTING 1 -s 10.0.1.2 -p udp -m comment --comment "nat udp connections" -j MASQUERADE
```

Now lets explain every one of this lines:

1. Redirect all the tcp traffic that came from the virtual machine to our proxy on port 8080
2. Accept all the traffic that go from the pod to the virtual machine
3. Nat all the udp praffic that came from the virtual machine

This solution use a container I created that have two process inside, one for the egress traffic of the virtual machine and one for the ingress traffic.
For the egress traffic i used a program writed in golang, and for the ingress traffic I used haproxy.

The nat-proxy used a system call to get the original destination address and port that its been redirected to us from the iptable rules I created.

The extract function:
```
func getOriginalDst(clientConn *net.TCPConn) (ipv4 string, port uint16, newTCPConn *net.TCPConn, err error) {
    if clientConn == nil {
        log.Printf("copy(): oops, dst is nil!")
        err = errors.New("ERR: clientConn is nil")
        return
    }

    // test if the underlying fd is nil
    remoteAddr := clientConn.RemoteAddr()
    if remoteAddr == nil {
        log.Printf("getOriginalDst(): oops, clientConn.fd is nil!")
        err = errors.New("ERR: clientConn.fd is nil")
        return
    }

    srcipport := fmt.Sprintf("%v", clientConn.RemoteAddr())

    newTCPConn = nil
    // net.TCPConn.File() will cause the receiver's (clientConn) socket to be placed in blocking mode.
    // The workaround is to take the File returned by .File(), do getsockopt() to get the original
    // destination, then create a new *net.TCPConn by calling net.Conn.FileConn().  The new TCPConn
    // will be in non-blocking mode.  What a pain.
    clientConnFile, err := clientConn.File()
    if err != nil {
        log.Printf("GETORIGINALDST|%v->?->FAILEDTOBEDETERMINED|ERR: could not get a copy of the client connection's file object", srcipport)
        return
    } else {
        clientConn.Close()
    }

    // Get original destination
    // this is the only syscall in the Golang libs that I can find that returns 16 bytes
    // Example result: &{Multiaddr:[2 0 31 144 206 190 36 45 0 0 0 0 0 0 0 0] Interface:0}
    // port starts at the 3rd byte and is 2 bytes long (31 144 = port 8080)
    // IPv4 address starts at the 5th byte, 4 bytes long (206 190 36 45)
    addr, err := syscall.GetsockoptIPv6Mreq(int(clientConnFile.Fd()), syscall.IPPROTO_IP, SO_ORIGINAL_DST)
    log.Printf("getOriginalDst(): SO_ORIGINAL_DST=%+v\n", addr)
    if err != nil {
        log.Printf("GETORIGINALDST|%v->?->FAILEDTOBEDETERMINED|ERR: getsocketopt(SO_ORIGINAL_DST) failed: %v", srcipport, err)
        return
    }
    newConn, err := net.FileConn(clientConnFile)
    if err != nil {
        log.Printf("GETORIGINALDST|%v->?->%v|ERR: could not create a FileConn fron clientConnFile=%+v: %v", srcipport, addr, clientConnFile, err)
        return
    }
    if _, ok := newConn.(*net.TCPConn); ok {
        newTCPConn = newConn.(*net.TCPConn)
        clientConnFile.Close()
    } else {
        errmsg := fmt.Sprintf("ERR: newConn is not a *net.TCPConn, instead it is: %T (%v)", newConn, newConn)
        log.Printf("GETORIGINALDST|%v->?->%v|%s", srcipport, addr, errmsg)
        err = errors.New(errmsg)
        return
    }

    ipv4 = itod(uint(addr.Multiaddr[4])) + "." +
        itod(uint(addr.Multiaddr[5])) + "." +
        itod(uint(addr.Multiaddr[6])) + "." +
        itod(uint(addr.Multiaddr[7]))
    port = uint16(addr.Multiaddr[2])<<8 + uint16(addr.Multiaddr[3])

    return
}
```

After we get the original destination address and port we start a connection to it and copy all the packets.
```
var streamWait sync.WaitGroup
streamWait.Add(2)

streamConn := func(dst io.Writer, src io.Reader) {
    io.Copy(dst, src)
    streamWait.Done()
}

go streamConn(remoteConn, VMconn)
go streamConn(VMconn, remoteConn)

streamWait.Wait()
```

The Haproxy help us with the ingress traffic with the follow configuration
```
defaults
  mode tcp
frontend main
  bind *:9080
  default_backend guest
backend guest
  server guest 10.0.1.2:9080 maxconn 2048
```

It send all the traffic to our virtual machine on the service port the machine is listening.

[Code repository](https://github.com/SchSeba/NatProxy)

### nat proxy conclusions
This solution is a general solution, not a dedicated solution to istio only. Its make the vm traffic look like a regular process inside the pod so it will work with any sidecars projects

Egress data flow in this solution:

![nat-proxy-egress-traffic](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/nat-proxy-egress-traffic.png)

Ingress data flow in this solution:

![nat-proxy-ingress-traffic](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/nat-proxy-ingress.png)

Pros:
* No external modules needed
* Works with any sidecar solution

Cons:
* Not other process can change the iptables rules
* External process needed
* The traffic is passed to user space
* Only support ingress TCP connection 

## Iptables with a trasperent-proxy process
This is the last solution I used in my research, it use a kernel module named TPROXY The [official documentation](https://www.kernel.org/doc/Documentation/networking/tproxy.txt) from the linux kernel documentation.

For this solution a created the following architecture

![semi-tproxy-Diagram](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/semi-tproxy-diagram.png)

With the follow yaml configuration
```
apiVersion: v1
kind: Service
metadata:
  name: application-devel
  labels:
    app: libvirtd-devel
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: libvirtd-devel
  type: LoadBalancer

---
apiVersion: v1
kind: Service
metadata:
  name: libvirtd-client-devel
  labels:
    app: libvirtd-devel
spec:
  ports:
  - port: 16509
    name: client-connection
  - port: 5900
    name: spice
  - port: 22
    name: ssh
  selector:
    app: libvirtd-devel
  type: LoadBalancer
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  creationTimestamp: null
  name: libvirtd-devel
spec:
  replicas: 1
  strategy: {}
  template:
    metadata:
      annotations:
        sidecar.istio.io/status: '{"version":"43466efda2266e066fb5ad36f2d1658de02fc9411f6db00ccff561300a2a3c78","initContainers":["istio-init","enable-core-dump"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-certs"]}'
      creationTimestamp: null
      labels:
        app: libvirtd-devel
    spec:
      containers:
      - image: docker.io/sebassch/mylibvirtd:devel
        imagePullPolicy: Always
        name: compute
        ports:
        - containerPort: 9080
        - containerPort: 16509
        - containerPort: 5900
        - containerPort: 22
        securityContext:
          capabilities:
            add:
            - ALL
          privileged: true
          runAsUser: 0
        volumeMounts:
          - mountPath: /var/lib/libvirt/images
            name: test-volume
          - mountPath: /host-dev
            name: host-dev
          - mountPath: /host-sys
            name: host-sys
        resources: {}
        env:
          - name: LIBVIRTD_DEFAULT_NETWORK_DEVICE
            value: "eth0"
      - image: docker.io/sebassch/mytproxy:devel
        imagePullPolicy: Always
        name: proxy
        resources: {}
        securityContext:
          privileged: true
          capabilities:
            add:
            - NET_ADMIN
      - args:
        - proxy
        - sidecar
        - --configPath
        - /etc/istio/proxy
        - --binaryPath
        - /usr/local/bin/envoy
        - --serviceCluster
        - productpage
        - --drainDuration
        - 45s
        - --parentShutdownDuration
        - 1m0s
        - --discoveryAddress
        - istio-pilot.istio-system:15005
        - --discoveryRefreshDelay
        - 1s
        - --zipkinAddress
        - zipkin.istio-system:9411
        - --connectTimeout
        - 10s
        - --statsdUdpAddress
        - istio-mixer.istio-system:9125
        - --proxyAdminPort
        - "15000"
        - --controlPlaneAuthPolicy
        - MUTUAL_TLS
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: INSTANCE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        image: docker.io/istio/proxy:0.7.1
        imagePullPolicy: IfNotPresent
        name: istio-proxy
        resources: {}
        securityContext:
          privileged: false
          readOnlyRootFilesystem: true
          runAsUser: 1337
        volumeMounts:
        - mountPath: /etc/istio/proxy
          name: istio-envoy
        - mountPath: /etc/certs/
          name: istio-certs
          readOnly: true
      initContainers:
      - args:
        - -p
        - "15001"
        - -u
        - "1337"
        - -i
        - 10.96.0.0/12,192.168.0.0/16
        image: docker.io/istio/proxy_init:0.7.1
        imagePullPolicy: IfNotPresent
        name: istio-init
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
      - args:
        - -c
        - sysctl -w kernel.core_pattern=/etc/istio/proxy/core.%e.%p.%t && ulimit -c
          unlimited
        command:
        - /bin/sh
        image: alpine
        imagePullPolicy: IfNotPresent
        name: enable-core-dump
        resources: {}
        securityContext:
          privileged: true
      volumes:
      - emptyDir:
          medium: Memory
        name: istio-envoy
      - name: istio-certs
        secret:
          optional: true
          secretName: istio.default
      - name: host-dev
        hostPath:
          path: /dev
          type: Directory
      - name: host-sys
        hostPath:
          path: /sys
          type: Directory
      - name: test-volume
        hostPath:
          # directory location on host
          path: /bricks/brick1/volume/Images
          # this field is optional
          type: Directory
status: {}

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: gateway-devel
  annotations:
    kubernetes.io/ingress.class: "istio"
spec:
  rules:
  - http:
      paths:
      - path: /devel-myvm
        backend:
          serviceName: application-devel
          servicePort: 9080
```

When the tproxy container start it run an entry point script for iptables configuration but this time the proxy redirect came in the mangle table and not in the nat table that because TPROXY module avilable only in the mangle table.

```
TPROXY
This target is only valid in the mangle table, in the 
PREROUTING chain and user-defined chains which are only 
called from this chain.  It redirects the packet to a local 
socket without changing the packet header in any way. It can
also change the mark value which can then be used in 
advanced routing rules. 
```

iptables rules:
```
iptables -t mangle -vL
iptables -t mangle -N KUBEVIRT_DIVERT
iptables -t mangle -A KUBEVIRT_DIVERT -j MARK --set-mark 8
iptables -t mangle -A KUBEVIRT_DIVERT -j ACCEPT

table=mangle
iptables -t ${table} -N KUBEVIRT_INBOUND
iptables -t ${table} -A PREROUTING -p tcp -m comment --comment "Kubevirt Spice"  --dport 5900 -j RETURN
iptables -t ${table} -A PREROUTING -p tcp -m comment --comment "Kubevirt virt-manager"  --dport 16509 -j RETURN
iptables -t ${table} -A PREROUTING -p tcp -i vnet0 -j KUBEVIRT_INBOUND

iptables -t ${table} -N KUBEVIRT_TPROXY
iptables -t ${table} -A KUBEVIRT_TPROXY ! -d 127.0.0.1/32 -p tcp -j TPROXY --tproxy-mark 8/0xffffffff --on-port 9401
#iptables -t mangle -A KUBEVIRT_TPROXY ! -d 127.0.0.1/32 -p udp -j TPROXY --tproxy-mark 8/0xffffffff --on-port 8080

# If an inbound packet belongs to an established socket, route it to the
# loopback interface.
iptables -t ${table} -A KUBEVIRT_INBOUND -p tcp -m socket -j KUBEVIRT_DIVERT
#iptables -t mangle -A KUBEVIRT_INBOUND -p udp -m socket -j KUBEVIRT_DIVERT

# Otherwise, it's a new connection. Redirect it using TPROXY.
iptables -t ${table} -A KUBEVIRT_INBOUND -p tcp -j KUBEVIRT_TPROXY
#iptables -t mangle -A KUBEVIRT_INBOUND -p udp -j KUBEVIRT_TPROXY
iptables -t ${table} -I OUTPUT 1 -d 10.0.1.2 -j ACCEPT

table=nat
# Remove vm Connection from iptables rules
iptables -t ${table} -I PREROUTING 1 -s 10.0.1.2 -j ACCEPT
iptables -t ${table} -I OUTPUT 1 -d 10.0.1.2 -j ACCEPT

# Allow guest -> world -- using nat for UDP
iptables -t ${table} -I POSTROUTING 1 -s 10.0.1.2 -p udp -j MASQUERADE
```

For this solution we also need to load the bridge kernel module 
```
modprobe bridge
```

And create some ebtables rules so egress and ingress traffict from the virtial machine will exit the l2 rules and pass to the l3 rules:
```
  ebtables -t broute -F # Flush the table
    # inbound traffic
    ebtables -t broute -A BROUTING -p IPv4 --ip-dst 10.0.1.2 \
    -j redirect --redirect-target DROP
    # returning outbound traffic
    ebtables -t broute -A BROUTING -p IPv4 --ip-src 10.0.1.2 \
    -j redirect --redirect-target DROP
```

We also need to disable rp_filter on the virtual machine interface and the libvirt bridge interface
```
echo 0 > /proc/sys/net/ipv4/conf/virbr0/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/virbr0-nic/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/vnet0/rp_filter
```

After this configuration the container start the semi-tproxy process for egress traffic and the haproxy process for the ingress traffic.

The semi-tproxy program is a golag program,binding a listener socket with the IP_TRANSPARENT socket option
Preparing a socket to receive connections with TProxy is really no different than what is normally done when setting up a socket to listen for connections. The only difference in the process is before the socket is bound, the IP_TRANSPARENT socket option.
```
syscall.SetsockoptInt(fileDescriptor, syscall.SOL_IP, syscall.IP_TRANSPARENT, 1)
```

About IP_TRANSPARENT
```
IP_TRANSPARENT (since Linux 2.6.24)
Setting this boolean option enables transparent proxying on
this socket.  This socket option allows the calling applica‐
tion to bind to a nonlocal IP address and operate both as a
client and a server with the foreign address as the local
end‐point.  NOTE: this requires that routing be set up in
a way that packets going to the foreign address are routed 
through the TProxy box (i.e., the system hosting the 
application that employs the IP_TRANSPARENT socket option).
Enabling this socket option requires superuser privileges
(the CAP_NET_ADMIN capability).

TProxy redirection with the iptables TPROXY target also
requires that this option be set on the redirected socket.
```

Then he setting the IP_TRANSPARENT socket option on outbound connections
Same goes for making connections to a remote host pretending to be the client, the IP_TRANSPARENT socket option is set and the Linux kernel will allow the bind so along as a connection was intercepted with those details being used for the bind.

When the process get a new connection he start a connection to the read destination address and copy the traffic between both sockets
```
var streamWait sync.WaitGroup
streamWait.Add(2)

streamConn := func(dst io.Writer, src io.Reader) {
    io.Copy(dst, src)
    streamWait.Done()
}

go streamConn(remoteConn, VMconn)
go streamConn(VMconn, remoteConn)

streamWait.Wait()
```

The Haproxy help us with the ingress traffic with the follow configuration
```
defaults
  mode tcp
frontend main
  bind *:9080
  default_backend guest
backend guest
  server guest 10.0.1.2:9080 maxconn 2048
```

It send all the traffic to our virtual machine on the service port the machine is listening.

[Code repository](https://github.com/SchSeba/SemiTrasperentProxy)

### tproxy conclusions
This solution is a general solution, not a dedicated solution to istio only. Its make the vm traffic look like a regular process inside the pod so it will work with any sidecars projects

Egress data flow in this solution:

![tproxy-egress-traffic](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/semi-tproxy-egress.png)

Ingress data flow in this solution:

![tproxy-ingress-traffic](../assets/2018-06-03-Research-run-VMs-with-istio-service-mesh/nat-proxy-ingress.png)

Pros:
* other process can change the nat table (this solution works on the mangle table)
* better preformance comparing to nat-proxy
* Works with any sidecar solution

Cons:
* Need NET_ADMIN capability for the docker
* External process needed
* The traffic is passed to user space
* Only support ingress TCP connection 


# Research Conclustion
Kubevirt shows it is possible to run virtual machines inside a kubernetes cluster, and this post shows that the virtual machine can also get the benefit of it.