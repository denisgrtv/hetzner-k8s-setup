#!/bin/bash
# Initializing cluster
kubeadm init \
--control-plane-endpoint=<node_or_load_balancer_ip> \
--apiserver-advertise-address=<node_ip> \
--cri-socket=unix:///var/run/cri-dockerd.sock \
--pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Applying network
kubectl apply -f https://github.com/flannel-io/flannel/releases/download/v0.22.0/kube-flannel.yml

# (Optional) Setup Hetzner cloud services
# Installing Cloud controller manager
# see: https://github.com/hetznercloud/hcloud-cloud-controller-manager

# Patching network becouse it can't start without cloud controller
kubectl -n kube-flannel patch ds kube-flannel-ds --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'

kubectl -n kube-system create secret generic hcloud --from-literal=token=<hetzner token> --from-literal=network=<hetnzer private network name>

kubectl apply -f https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/v1.15.0/ccm-networks.yaml

# After cloud controller initialization restart node or flannel services for network settings update

# (Optional) Installing autoscaler
# see: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/hetzner/README.md

# Get example file from origin repository
# Or you can get example from ./cluster-autoscaler
# wget https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/hetzner/examples/cluster-autoscaler-run-on-master.yaml

# Change toleration and node affinity to node-role.kubernetes.io/control-plane
# Config variables and pools
# Change image
# Delete or update volumes and imagePullSecrets sections

# Apply edited file
# kubectl apply -f ./cluster-autoscaler-run-on-master.yaml
# or 
# kubectl apply -f ./cluster-autoscaler

# (Optional) Installing CSI plugin
# see https://github.com/hetznercloud/csi-driver/blob/main/docs/kubernetes/README.md
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v2.3.2/deploy/kubernetes/hcloud-csi.yml
# (Optional) Sticking CSI controller to master node
kubectl -n kube-system patch deploy hcloud-csi-controller --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node-role.kubernetes.io/control-plane","effect":"NoSchedule"}}]'
kubectl -n kube-system patch deploy hcloud-csi-controller --patch '{"spec": {"template": {"spec": {"affinity": {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {"nodeSelectorTerms": [{"matchExpressions": [{"key": "node-role.kubernetes.io/control-plane","operator": "Exists"}]}]}}}}}}}'

# (Optional) Allow run pods on master node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-