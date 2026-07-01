#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Install required packages
apt-get update && apt-get install -y git openssl

echo "############################################################"
echo "### Installing K3s Addons ###"
echo "############################################################"

# Ensure KUBECONFIG is set for subsequent kubectl commands
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# --- 1. Install Metrics Server ---
# The Metrics Server is crucial for HPA (Horizontal Pod Autoscaler) to gather container resource usage.
echo
echo "-> Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
echo "Metrics Server installation/update command sent."
echo

# --- 2. Install Vertical Pod Autoscaler (VPA) ---
# The official installation script `vpa-up.sh`.
echo "-> Installing Vertical Pod Autoscaler (VPA)..."
if [ ! -d "autoscaler" ]; then
    echo "Cloning autoscaler repository..."
    git clone https://github.com/kubernetes/autoscaler.git
fi

cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
cd ../.. # Return to the original directory
echo "VPA installation/update script finished."
echo