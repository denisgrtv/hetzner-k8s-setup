# hetzner-k8s-setup
Notes how to setup kubernetes cluster in Hetzner cloud

## Versions
- kubernetes: 1.27.2
- OS: Rocky linux 9
- Docker: 24.0.2

## Features
- Container runtime: Docker
- Network: [Flannel](https://github.com/flannel-io/flannel/tree/master)
- [Cloud controller manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
  - Private network management
  - Nodes interfaces settings
  - Load balancers
- [Autoscaler](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/hetzner/README.md)
- [Storage driver](https://github.com/hetznercloud/csi-driver/blob/main/docs/kubernetes/README.md)

## Preparing
For this step you can use web cloud console or [hcloud cli](https://github.com/hetznercloud/cli) app

- (Optional) Create firewall with no-limit outbound, allow inbound TCP 22 and ICMP
- (Optional) Create placement group
- (Optional) Upload your ssh key
- Create private network 10.0.0.0/16
- Create access token with read and write permissions
- Create master node (Ex. CX21) with attached firewall, network, placement group and ssh key

## Installation
- Follow [cloud-init-all.sh](./cloud-init-all.sh) in master node
- Make master node snapshot for worker nodes
- Follow [cloud-init-master.sh](./cloud-init-master.sh)
- Add base64 encoded join command to autoscaler (ex. in [cloud-init-worker.sh](./cloud-init-worker.sh))
- Test your setup with [echoserver](./echoserver) deployment