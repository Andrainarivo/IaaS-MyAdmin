#!/bin/bash
set -e

echo "=== Début de l'installation du Worker K3s ==="
apt-get update && apt-get install -y curl netcat-openbsd

# Attente de la disponibilité de l'API Kubernetes du master
until nc -z -v -w5 "${MASTER_IP}" 6443; do
  echo "En attente du Master K3s (${MASTER_IP}:6443)..."
  sleep 5
done

# Connexion au master en tant qu'agent worker
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" K3S_URL="https://${MASTER_IP}:6443" sh -s - agent \
  --node-ip=$(hostname -I | awk '{print $1}')