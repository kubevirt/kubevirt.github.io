tee cluster.yaml <<EOC
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
- role: worker
EOC

kind create cluster --config cluster.yaml
