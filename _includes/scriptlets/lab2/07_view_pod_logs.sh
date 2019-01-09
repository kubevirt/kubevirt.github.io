kubectl get pvc {{ site.data.labs_kubernetes_variables.cdi_lab.pvc_name }} -o yaml
kubectl get pod
# replace with your importer pod name
kubectl logs importer-fedora-pnbqh   # Substitute your importer-fedora pod name here.
