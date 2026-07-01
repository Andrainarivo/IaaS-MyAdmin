#!/bin/bash
set -e

echo "=== Starting K3s Worker installation ==="
apt-get update && apt-get install -y curl

if [ -z "$MASTER_IP" ] || [ -z "$K3S_TOKEN" ]; then
  echo "Error: MASTER_IP and K3S_TOKEN environment variables must be set."
  exit 1
fi

# Install K3s agent, pointing to the master node
curl -sfL https://get.k3s.io | sh -s - agent --node-label "node-role.kubernetes.io/worker=" \
  --server https://${MASTER_IP}:6443 \
  --token ${K3S_TOKEN}

echo "=== K3s Worker installation complete. Node should join the cluster shortly. ==="