$ virtctl expose vmi vm1 --name=vm1-ssh --port=20222 --target-port=22 --type=NodePort
  Service vm1-ssh successfully exposed for vmi vm1

$ kubectl get svc
NAME      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
vm1-ssh   NodePort   10.101.226.150   <none>        20222:32495/TCP   24m
