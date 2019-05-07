kubectl get pvc fedora -o yaml
kubectl get pod # Make note of the pod name assigned to the import process
kubectl logs -f importer-fedora-pnbqh   # Substitute your importer-fedora pod name here.
