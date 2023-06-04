#!/bin/bash
# see: https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/baremetal/deploy.yaml
# (Optional) Allow runs on master node
kubectl -n ingress-nginx patch deploy ingress-nginx-controller --patch '{"spec": {"template": {"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane","operator": "Exists"}]}}}}'