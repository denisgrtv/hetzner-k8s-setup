#!/bin/bash
# see: https://cert-manager.io/docs/installation/
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
# (Optional) Allow runs on master node
kubectl -n cert-manager patch deploy cert-manager --patch '{"spec": {"template": {"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane","operator": "Exists"}]}}}}'
kubectl -n cert-manager patch deploy cert-manager-cainjector --patch '{"spec": {"template": {"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane","operator": "Exists"}]}}}}'
kubectl -n cert-manager patch deploy cert-manager-webhook --patch '{"spec": {"template": {"spec": {"tolerations": [{"key": "node-role.kubernetes.io/control-plane","operator": "Exists"}]}}}}'