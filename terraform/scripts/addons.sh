#!/bin/bash
set -e

# Installation des paquets requis
apt-get update && apt-get install -y git openssl

echo "=== Début de la configuration des Addons (VPA) ==="

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Attente active que K3s réponde
until kubectl get nodes &>/dev/null; do
  echo "Attente de l'API Server..."
  sleep 3
done

echo "=== Attente que le nœud Master passe au statut Ready ==="
# On utilise la commande native K8s pour attendre le statut Ready du master
kubectl wait --for=condition=Ready node/$(hostname) --timeout=60s

# Déploiement ou mise à jour du VPA
rm -rf /tmp/autoscaler
git clone https://github.com/kubernetes/autoscaler.git /tmp/autoscaler
cd /tmp/autoscaler/vertical-pod-autoscaler

# vpa-up.sh est idempotent (il peut être relancé sans tout casser)
./hack/vpa-up.sh

rm -rf /tmp/autoscaler
echo "=== Addons installés avec succès ==="