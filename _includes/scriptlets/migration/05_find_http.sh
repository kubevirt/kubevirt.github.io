IP=$(minikube ip)
PORT=$(kubectl get svc testvm-http -o jsonpath='{.spec.ports[0].nodePort}')
