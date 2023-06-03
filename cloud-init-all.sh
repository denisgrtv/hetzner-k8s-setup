#!/bin/bash
# System setup
yum update -y
yum install -y git iptables-services yum-utils

# (Optional) disable ssh password auth
sed -i 's/^#PasswordAuthentication yes$/PasswordAuthentication no/' /etc/ssh/sshd_config

systemctl restart sshd

# Network setup
# see: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
### Forwarding IPv4 and letting iptables see bridged traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Installing docker
# see: https://docs.docker.com/engine/install/
# see: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y \
docker-ce-3:24.0.2-1.el9 \
docker-ce-cli-1:24.0.2-1.el9 \
containerd.io-1.6.21-3.1.el9 \
docker-buildx-plugin-0.10.5-1.el9 \
docker-compose-plugin-2.18.1-1.el9

# (Optional) Additional docker settings
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl enable --now docker

# Installing CRI for docker
# see: https://github.com/Mirantis/cri-dockerd
git clone https://github.com/Mirantis/cri-dockerd.git

wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable --now cri-docker.service
systemctl enable --now cri-docker.socket

# Installing k8s
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Installing CNI plugin for Flannel
# see: https://github.com/flannel-io/flannel/tree/master
mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.2.0.tgz

# you can see availible vesions with command:
# yum list kubelet --disableexcludes=kubernetes --showduplicates
yum install -y kubelet-1.27.2-0 kubeadm-1.27.2-0 kubectl-1.27.2-0 --disableexcludes=kubernetes

systemctl enable --now kubelet

# (Optional) If you want to run cluster with cloud countroller
cat <<EOF | sudo tee /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS=--cloud-provider=external
EOF

systemctl daemon-reload && systemctl restart kubelet