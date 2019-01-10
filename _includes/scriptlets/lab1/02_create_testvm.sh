kubectl apply -f {{ site.data.labs_kubernetes_variables.use_kubevirt_lab.vm_manifest }}
  virtualmachine.kubevirt.io "testvm" created
  virtualmachineinstancepreset.kubevirt.io "small" created
