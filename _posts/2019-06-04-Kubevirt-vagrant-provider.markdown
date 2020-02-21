---
layout: post
author: pkliczewski
title: KubeVirt vagrant provider
description: The post describes how to use kubevirt vagrant provider
navbar_active: Blogs
pub-date: June 4
pub-year: 2019
category: news
comments: true
tags: [vagrant, lifecycle, virtual machines]
---

# Introduction

Vagrant is a command line utility for managing the lifecycle of virtual machines. There are number of providers available which allow to control and provision virtual machines in different environment. In this blog post we update how to use the [provider](https://github.com/pkliczewski/vagrant-kubevirt) to manage [KubeVirt](https://kubevirt.io/).

The KubeVirt Vagrant provider implements the following features:

- Manages virtual machines lifecycle - start, halt, status and destroy.
- Creates virtual machines using templates, container disks or existing pvc.
- Supports Vagrant built-in provisioners.
- Provides ability to ssh to the virtual machines
- Supports folder synchronization by using rsync

# Installation

In order to use the provider we need to install Vagrant first. The steps how to do it are available [here](https://www.vagrantup.com/intro/getting-started/install.html). Once command line tool is available in our system, we can install the plugin by running:

```
$ vagrant plugin install vagrant-kubevirt
```

Now, we can obtain predefined box and start it using:

```
$ vagrant up --provider=kubevirt
```

# Virtual machine definition

Instead of building a virtual machine from scratch, which would be a slow and tedious process, Vagrant uses a base image as template for virtual machines. These base images are known as "boxes" and every provider must introduce its own box format. The provider introduces _kubevirt_ boxes.
You can view an example box [here](https://github.com/pkliczewski/vagrant-kubevirt/blob/master/example_box/).

There are two ways to tell Vagrant, how to connect to KubeVirt cluster in Vagrantfile:

- use Kubernetes configuration file. When no other connection details provided, the provider will look for kubeconfig using value of KUBECONFIG environment variable or \$HOME/.kube/config location.
- define connection details as part of box definition

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :kubevirt do |kubevirt|
    kubevirt.hostname = '<kubevirt host>'
    kubevirt.port = '<kubevirt port>'
    kubevirt.token = '<token>'
  end
end
```

Values used in above sample box:

- kubevirt host - Hostname where KubeVirt is deployed
- kubevirt port - Port on where KubeVirt is listening
- token - User token used to authenticate any request

There are number of options we can customize for specific a virtal machine:

- cpus - Number of cpus used by a virtual machine
- memory - Amount of memory by a virtual machine

We can choose one of the three following options:

- template - Name of a template which will be used to create the virtual machine
- image - Name of a container disk stored in a registry
- pvc - Name of persistent volume claim containing virtual machine disk

Below, you can find sample Vagrantfile exposing all the supported features:

```ruby
Vagrant.configure("2") do |config|
  # name of the box
  config.vm.box = 'kubevirt'
  # vm boot timeout
  config.vm.boot_timeout = 360

  # disables default vagrant folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # synchoronizes a directory between a host and virtual machine
  config.vm.synced_folder "$HOME/src", "/srv/website", type: "rsync"

  # uses provision action to touch a file in a virtual machine
  config.vm.provision "shell" do |s|
    s.inline = "touch example.txt"
  end

  # defines virtual machine resources and source of disk
  config.vm.provider :kubevirt do |kubevirt|
    kubevirt.cpus = 2
    kubevirt.memory = 512
    kubevirt.image = 'kubevirt/fedora-cloud-registry-disk-demo'
  end

  # defines a user configured on a virtual machine using cloud-init
  config.ssh.username = 'vagrant'
  config.ssh.password = 'vagrant'
end
```

# Usage

Now, once we defined a virtual machine we can see how to use the provider to manage it.

```
vagrant up
```

The above command starts a virtual machines and performs any additonal operations defined in the Vagrantfile like provisioning, folder synchronization setup. For more information check [here](https://www.vagrantup.com/docs/cli/up.html)

```
vagrant halt
```

The above command stops a virtual machine. For more information check [here](https://www.vagrantup.com/docs/cli/halt.html)

```
vagrant status
```

The above command provides status of a virtual machine. For more information check [here](https://www.vagrantup.com/docs/cli/status.html)

```
vagrant destroy
```

The above command stops a virtual machine and destroys all the resources used. For more information check [here](https://www.vagrantup.com/docs/cli/destroy.html)

```
vagrant provision
```

The above command runs configured provisioners for specific virtual machine. For more information check [here](https://www.vagrantup.com/docs/cli/provision.html)

```
vagrant ssh
```

The above command ssh to running virtual machine. For more information check [here](https://www.vagrantup.com/docs/cli/ssh.html)

# Future work

There are still couple of features we would like to implement such as network management or user friendly box packaging.
