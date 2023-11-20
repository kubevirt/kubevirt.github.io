---
layout: post
author: Alberto Losada Grande, Pedro Ibáñez Requena
description: Overview of different user interface options to manage KubeVirt
navbar_active: Blogs
category: news
comments: true
title: KubeVirt user interface options
tags:
  [
    octant,
    okd,
    openshift console,
    cockpit,
    noVNC,
    user interface,
    web interface,
    virtVNC,
    OKD console,
  ]
pub-date: December
pub-year: 2019
---

> The user interface (UI), in the industrial design field of human–computer interaction, is the space where interactions between humans and machines occur. The goal of this interaction is to allow effective operation and control of the machine from the human end, whilst the machine simultaneously feeds back information that aids the operators' decision-making process. [Wikipedia:User Interface](https://en.wikipedia.org/wiki/User_interface)

In this blogpost we show the results of a research about the different options existing in the market to enable KubeVirt with a user interface to manage, access and control the life cycle of the Virtual Machines inside Kubernetes with KubeVirt.

The different UI options available for KubeVirt that we have been checking, at the moment of writing this article, are the following:

- [Octant](https://github.com/vmware-tanzu/octant)
- [OKD: The Origin Community Distribution of Kubernetes](https://github.com/openshift/okd)
- [OpenShift console](https://github.com/openshift/console) running on vanilla Kubernetes
- [Cockpit](https://cockpit-project.org/)
- [noVNC](https://novnc.com/info.html)

## Octant

<img src="/assets/2019-12-19-KubeVirt_UI_options/octant-logo.png" alt="Octant logo">

As the [Octant webpage](https://octant.dev/) claims:

> Octant is an open-source developer-centric web interface for Kubernetes that lets you inspect a Kubernetes cluster and its applications. Octant is a tool for developers to understand how applications run on a Kubernetes cluster. It aims to be part of the developer's toolkit for gaining insight and approaching complexity found in Kubernetes. Octant offers a combination of introspective tooling, cluster navigation, and object management along with a plugin system to further extend its capabilities.

Some of the key features of this tool can be checked in their [latest release notes](https://reference.octant.dev/):

- **Resource Viewer**: Graphically visualize relationships between objects in a Kubernetes cluster. The status of individual objects is represented by colour to show workload performance.
- **Summary View**: Consolidated status and configuration information in a single page aggregated from output typically found using multiple kubectl commands.
- **Port Forward**: Forward a local port to a running pod with a single button for debugging applications and even port forward multiple pods across namespaces.
- **Log Stream**: View log streams of pod and container activity for troubleshooting or monitoring without holding multiple terminals open.
- **Label Filter**: Organize workloads with label filtering for inspecting clusters with a high volume of objects in a namespace.
- **Cluster Navigation**: Easily change between namespaces or contexts across different clusters. Multiple kubeconfig files are also supported.
- **Plugin System**: Highly extensible plugin system for users to provide additional functionality through gRPC. Plugin authors can add components on top of existing views.

We installed it and found out that:

- Octant provides a very basic dashboard for Kubernetes and it is pretty straightforward to install. It can be installed in your laptop or in a remote server.
- Regular Kubernetes objects can be seen from the UI. Pod logs can be checked as well. However, mostly everything is in view mode, even the YAML description of the objects. Therefore, as a developer or cluster operator you cannot edit YAML files directly from the UI
- Custom resources (CRs) and custom resource definitions (CRDs) are automatically detected and shown in the UI. This means that KubeVirt CRs can be viewed from the dashboard. However, VirtualMachines and VirtualMachineInstances cannot be modified from Octant, they can only be deleted.
- There is an option to extend the functionality adding [plugins](https://reference.octant.dev/?path=/docs/docs-plugins-1-getting-started--page) to the dashboard.
- No specific options to manage KubeVirt workloads have been found.

<video autoplay loop muted playsinline src="/assets/2019-12-19-KubeVirt_UI_options/octant.mp4" type="video/mp4" width="1280" height="720"></video>

With further work and investigation, it could be an option to develop a specific plugin to enable remote console or VNC access to KubeVirt workloads.

## OKD: The Origin Community Distribution of Kubernetes

<img src="/assets/2019-12-19-KubeVirt_UI_options/okd_logo.png" alt="OKD logo">

As defined in the [official webpage](https://www.okd.io/):

> OKD is a distribution of Kubernetes optimized for continuous application development and multi-tenant deployment. OKD adds developer and operations-centric tools on top of Kubernetes to enable rapid application development, easy deployment and scaling, and long-term lifecycle maintenance for small and large teams. OKD is the upstream Kubernetes distribution embedded in Red Hat OpenShift.
> OKD embeds Kubernetes and extends it with security and other integrated concepts. OKD is also referred to as Origin in github and in the documentation. An OKD release corresponds to the Kubernetes distribution - for example, OKD 1.10 includes Kubernetes 1.10.

A few weeks ago Kubernetes distribution [OKD4](https://github.com/openshift/okd) was released as preview. OKD is the official upstream version of Red Hat's OpenShift. Since OpenShift includes KubeVirt (Red Hat calls it [CNV](https://docs.openshift.com/container-platform/4.2/cnv/cnv_install/cnv-about-cnv.html)) as a tech-preview feature since a couple of releases, there is already a lot of integration going on between OKD console and KubeVirt.

Note that OKD4 is in preview, which means that only a subset of platforms and functionality will be available until it reaches beta. That being said, we have we found a similar behaviour as testing KubeVirt with OpenShift. We have noticed that from the UI a user can:

- Install the KubeVirt operator from the operator marketplace.
- Create Virtual Machines by importing YAML files or following a wizard. The wizard prevents you from moving to the next screen until you provide values in the required fields.
- Modify the status of the Virtual Machine: stop, start, migrate, clone, edit label, edit annotations, edit CD-ROMs and delete
- Edit network interfaces. It is possible to add multiple network interfaces to the VM.
- Add disks to the VM
- Connect to the VM via serial or VNC console.
- Edit the YAML object files online.
- Create VM templates. The web console features an interactive wizard that guides you through the Basic Settings, Networking, and Storage screens to simplify the process of creating virtual machine templates.
- Check VM events in real time.
- Gather metrics and utilization of the VM.
- Pretty much everything you can do with KubeVirt from the command line.

<video autoplay loop muted playsinline src="/assets/2019-12-19-KubeVirt_UI_options/okd.mp4" type="video/mp4" width="1280" height="720"></video>

One of the drawbacks is that the current [KubeVirt HCO operator](https://operatorhub.io/operator/kubevirt) contains KubeVirt version 0.18.1, which is quite outdated. Note that last week version 0.24 of KubeVirt was released. Using such an old release could cause some issues when creating VMs using newer container disk images. For instance, we have not been able to run the latest [Fedora cloud container disk image](https://hub.docker.com/r/kubevirt/fedora-cloud-container-disk-demo) and instead we were forced to use the one tagged as v0.18.1 which matches the version of KubeVirt deployed.

If for any reason there is a need to deploy the latest version, it can be done by running the following script which applies directly the HCO operator: [unreleased bundles using the hco without marketplace](https://github.com/kubevirt/hyperconverged-cluster-operator#using-the-hco-without-olm-or-marketplace). Note that in this case automatic updates to KubeVirt are not triggered or advised automatically in OKD as it happens with the operator.

## OpenShift console (bridge)

There is actually a [KubeVirt Web User Interface](https://github.com/kubevirt/web-ui), however the standalone project was deprecated in favor of OpenShift Console where it is included as a plugin.

As we reviewed previously the [OpenShift web console](https://github.com/openshift/console) is just another piece inside OKD. It is an independent part and, as it is stated in their official GitHub repository, it can run on top of native Kubernetes. OpenShift Console a.k.a bridge is defined as:

> a friendly kubectl in the form of a single page web application. It also integrates with other services like monitoring, chargeback, and OLM. Some things that go on behind the scenes include:

- Proxying the Kubernetes API under /api/kubernetes
- Providing additional non-Kubernetes APIs for interacting with the cluster
- Serving all frontend static assets
- User Authentication

Then, as briefly explained in their [repository](https://github.com/openshift/console#native-kubernetes), our Kubernetes cluster can be configured to run the OpenShift Console and leverage its integrations with KubeVirt. Features related to KubeVirt are similar to the ones found in the OKD installation except:

- KubeVirt installation is done using the [Hyperconverged Cluster Operator (HCO) without OLM or Marketplace](https://github.com/kubevirt/hyperconverged-cluster-operator#using-the-hco-without-olm-or-marketplace) instead of the KubeVirt operator. Therefore, available updates to KubeVirt are not triggered or advised automatically
- Virtual Machines objects can only be created from YAML. Although the wizard dialog is still available in the console, it does not function properly because it uses specific OpenShift objects under the hood. These objects are not available in our native Kubernetes deployment.
- Connection to the VM via serial or VNC console is flaky.
- VM templates can only be created from YAML. The wizard dialog is based on OpenShift templates.

<video autoplay loop muted playsinline src="/assets/2019-12-19-KubeVirt_UI_options/bridge-k8s.mp4" type="video/mp4" width="1280" height="720"></video>

Note that the OpenShift console documentation briefly points out how to integrate the OpenShift console with a native Kubernetes deployment. It is uncertain if it can be installed in any other Kubernetes cluster.

## Cockpit

<img src="/assets/2019-12-19-KubeVirt_UI_options/cockpit-logo.png" alt="Cockpit logo">

When testing cockpit in a CentOS 7 server with a Kubernetes cluster and KubeVirt we have realised that some of the containers/k8s features have to be enabled installing extra cockpit packages:

- To see the containers and images the package `cockpit-docker` has to be installed, then a new option called containers appears in the menu.

![Containers](/assets/2019-12-19-KubeVirt_UI_options/cockpit_containers_800.png "cockpit containers")

- To see the k8s cluster the package `cockpit-kubernetes` has to be installed and a new tab appears in the left menu. The new options allow you to:

  - **Overview**: filtering by project, it shows Pods, volumes, Nodes, services and resources used.

![Cluster overview](/assets/2019-12-19-KubeVirt_UI_options/cockpit_k8s_cluster_overview_800.png "cockpit cluster overview")

- **Nodes**: nodes and the resources used are being shown here.
- **Containers**: a full list of containers and some metadata about them is displayed in this option.
- **Topology**: A graph with the pods, services and nodes is shown in this option.

![Cluster topology](/assets/2019-12-19-KubeVirt_UI_options/cockpit_k8s_topology_800.png "cockpit cluster topology")

- **Details**: allows to filter by project and type of resource and shows some metadata in the results.
- **Volumes**: allows to filter by project and shows the volumes with the type and the status.

In CentOS 7 there are also the following packages:

- `cockpit-machines.x86_64` : Cockpit user interface for virtual machines. If "virt-install" is installed, you can also create new virtual machines.
  It adds a new option in the main menu called Virtual Machines but it uses libvirt and is not KubeVirt related.
- `cockpit-machines-ovirt.noarch` : Cockpit user interface for oVirt virtual machines, like the package above but with support for ovirt.

At the moment none of the cockpit complements has support for KubeVirt Virtual Machine.

KubeVirt support for cockpit was [removed from fedora 29](https://bugzilla.redhat.com/show_bug.cgi?id=1629608)

## noVNC

noVNC is a JavaScript VNC client using WebSockets and HTML5 Canvas.
It just allows you to connect through VNC to the virtual Machine already deployed in KubeVirt.

No VM management or even a dashboard is enabled with this option, it's a pure DIY code that can embed the VNC access to the VM into HTML in any application or webpage.

## Summary

From the different options we have investigated, we can conclude that OpenShift Console along with OKD Kubernetes distribution provides a powerful way to manage and control our KubeVirt objects. From the user interface, a developer or operator can do pretty much everything you do in the command line. Additionally, users can create custom reusable templates to deploy their virtual machines with specific requirements. Wizard dialogs are provided as well in order to guide new users during the creation of their VMs.

OpenShift Console can also be considered as an interesting option in case your KubeVirt installation is running on a native Kubernetes cluster.

On the other hand, noVNC provides a lightweight interface to simply connect to the console of your virtual machine.

Octant, although it does not have any specific integration with KubeVirt, looks like a promising Kubernetes user interface that could be extended to manage our KubeVirt instances in the future.

> note "Note"
> We encourage our readers to let us know of user interfaces that can be used to manage our KubeVirt virtual machines. Then, we can include them in this list

## References

- [Octant](https://octant.dev)
- [OKD](https://www.okd.io/)
- [OKD Console](https://github.com/openshift/origin-web-console)
- [Cockpit](https://cockpit-project.org/)
- [virtVNC, noVNC for Kubevirt](https://github.com/wavezhang/virtVNC/)
