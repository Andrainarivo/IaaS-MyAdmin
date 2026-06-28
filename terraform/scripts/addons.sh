#!/bin/bash
set -e

# Install required packages
apt-get update && apt-get install -y git openssl

echo "=== Starting Addon Configuration (VPA) ==="

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Actively wait for K3s to respond
until kubectl get nodes &>/dev/null; do
  echo "Waiting for the API Server..."
  sleep 3
done

echo "=== Waiting for the Master node to be Ready ==="
# Use the native K8s command to wait for the master to be Ready
kubectl wait --for=condition=Ready node/$(hostname) --timeout=60s

# Deploy or update VPA
rm -rf /tmp/autoscaler
git clone https://github.com/kubernetes/autoscaler.git /tmp/autoscaler
cd /tmp/autoscaler/vertical-pod-autoscaler

# vpa-up.sh is idempotent (it can be re-run without breaking anything)
./hack/vpa-up.sh

rm -rf /tmp/autoscaler
echo "=== Addons installed successfully ==="