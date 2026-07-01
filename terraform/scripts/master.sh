#!/bin/bash
set -e

echo "=== Starting K3s Master installation ==="
apt-get update && apt-get install -y curl

# Install K3s with the token for agent nodes to join the cluster
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sh -s - server \
  --node-ip=$(hostname -I | awk '{print $1}') \
  --flannel-backend=vxlan

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "=== Waiting for the cluster to be ready ==="
until kubectl get nodes &>/dev/null; do
  echo "API server is not ready yet, waiting 3 seconds..."
  sleep 3
done

echo "=== Waiting for the Master node to be Ready ==="
# 2. Use the native K8s command to wait for the master to be Ready
kubectl wait --for=condition=Ready node/$(hostname) --timeout=60s

echo "=== K3s Master installation finished. Cluster is ready for addons. ==="