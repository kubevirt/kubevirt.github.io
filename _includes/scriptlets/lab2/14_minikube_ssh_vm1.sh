$ kubectl get vmi
NAME      AGE       PHASE     IP            NODENAME
vm1       109s      Running   172.17.0.16   minikube

$ minikube ssh
                         _             _
            _         _ ( )           ( )
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ ssh fedora@172.17.0.16
The authenticity of host '172.17.0.16 (172.17.0.16)' can't be established.
ECDSA key fingerprint is SHA256:QmJUvc8vbM2oXiEonennW7+lZ8rVRGyhUtcQBVBTnHs.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.17.0.16' (ECDSA) to the list of known hosts.
fedora@172.17.0.16's password:
