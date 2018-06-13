---
layout: post
author: SchSeba
description: In this post we will deploy a vm on top of kubernetes with istio service mesh
---

# Introduction

In this blog post we are going to talk about istio and virtual machines on top of Kubernetes. Some of the components we are going to use are [istio](https://istio.io/docs/concepts/what-is-istio/overview/), [libvirt](https://libvirt.org/index.html), [ebtables](http://ebtables.netfilter.org/), [iptables](https://en.wikipedia.org/wiki/Iptables), and [tproxy](https://github.com/LiamHaworth/go-tproxy). Please review the links provided for an overview and deeper dive into each technology

# Research explanation
Our research goal was to give virtual machines running inside pods (kubevirt project) all the benefits kubernetes have to offer, one of them is a service mesh like istio.

## Iptables only with dnat and source nat configuration
<span style="color:red;">This configuration is istio only!</span>

For this solution we created the following architecture

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

When the my-libvirt container starts it runs an entry point script for iptables configuration.

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

When the mynatproxy container starts it runs an entry point script for iptables configuration.

```
1. iptables -t nat -I PREROUTING 1 -p tcp -s 10.0.1.2 -m comment --comment "nat-proxy redirect" -j REDIRECT --to-ports 8080
2. iptables -t nat -I OUTPUT 1 -p tcp -s 10.0.1.2 -j ACCEPT
3. iptables -t nat -I POSTROUTING 1 -s 10.0.1.2 -p udp -m comment --comment "nat udp connections" -j MASQUERADE
```

Now lets explain every one of this lines:

1. Redirect all the tcp traffic that came from the virtual machine to our proxy on port 8080
2. Accept all the traffic that go from the pod to the virtual machine
3. Nat all the udp praffic that came from the virtual machine

This solution uses a container I created that has two processes inside, one for the egress traffic of the virtual machine and one for the ingress traffic.
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

When the tproxy container starts it runs an entry point script for iptables configuration but this time the proxy redirect came in the mangle table and not in the nat table that because TPROXY module avilable only in the mangle table.

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

Then we set the IP_TRANSPARENT socket option on outbound connections
Same goes for making connections to a remote host pretending to be the client, the IP_TRANSPARENT socket option is set and the Linux kernel will allow the bind so along as a connection was intercepted with those details being used for the bind.

When the process get a new connection we start a connection to the real destination address and copy the traffic between both sockets
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

The Haproxy helps us with the ingress traffic with the follow configuration
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