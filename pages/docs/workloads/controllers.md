---
layout: docs
title: Controllers
permalink: /docs/workloads/controllers.html
navbar_active: Docs
order: 10
---

# Controllers

Controllers provide the logic to manage virtual machine instances in a way that
addresses specific use-cases:

 * [VirtualMachineInstanceReplicaSet](controllers/virtual-machine-replica-set): Replicating stateless Virtual Machines.
 * [VirtualMachine](controllers/virtualmachine): Stateful Virtual Machine, similar to a StatefulSet with replicas set to 1.
