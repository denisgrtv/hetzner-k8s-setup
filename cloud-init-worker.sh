#!/bin/bash
kubeadm join <contorl_plane_ip>:6443 --token <token> \
--discovery-token-ca-cert-hash <hash> \
--cri-socket=unix:///var/run/cri-dockerd.sock