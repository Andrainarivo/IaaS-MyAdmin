#!/bin/bash
# ==============================================================================
# K3s Agent Installation Script (Worker Node)
# ==============================================================================
set -e

echo "=== [1/5] Validating environment prerequisites ==="

if [ -z "$MASTER_IP" ] || [ -z "$K3S_TOKEN" ]; then
  echo "Critical Error: MASTER_IP and K3S_TOKEN environment variables must be set." >&2
  exit 1
fi

echo "=== [2/5] Preparing package manager (apt) ==="

wait_for_apt_locks() {
  echo "Checking apt availability..."
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
    echo "Package manager is busy with system tasks (GCP init). Waiting 5 seconds..."
    sleep 5
  done
}

wait_for_apt_locks
apt-get update && apt-get install -y curl

echo "=== [3/5] Verifying Master Node readiness & connectivity ==="

# Loop until the Master's API server responds over the network
# This handles both the master boot delay and tests your GCP firewall rules
echo "Testing connection to K3s Master API at https://${MASTER_IP}:6443..."
while ! curl -k -s --connect-timeout 3 "https://${MASTER_IP}:6443" > /dev/null 2>&1; do
  echo "K3s Master API is unreachable. Retrying in 5 seconds..."
  sleep 5
done
echo "Successfully connected to K3s Master API!"

echo "=== [4/5] Downloading and provisioning K3s Agent ==="

curl -sfL https://get.k3s.io | \
  K3S_URL="https://${MASTER_IP}:6443" \
  K3S_TOKEN="${K3S_TOKEN}" \
  sh -s - agent

echo "=== [5/5] K3s Worker installation completed successfully ==="