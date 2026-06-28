#!/bin/bash
set -e

echo "=== Début de l'installation du Master K3s ==="
apt-get update && apt-get install -y curl

# Install K3s with the token for agent nodes to join the cluster
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sh -s - server \
  --node-ip=$(hostname -I | awk '{print $1}') \
  --flannel-backend=vxlan

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "=== Attente que le cluster soit prêt ==="
until kubectl get nodes &>/dev/null; do
  echo "L'APIserver n'est pas encore prêt, attente de 3 secondes..."
  sleep 3
done

echo "=== Attente que le nœud Master passe au statut Ready ==="
# 2. On utilise la commande native K8s pour attendre le statut Ready du master
kubectl wait --for=condition=Ready node/$(hostname) --timeout=60s

echo "=== Cluster K3s prêt ==="

echo "=== Installation du Vertical Pod Autoscaler (VPA) ==="
# Utilisation des manifestes officiels pour une installation stable
VPA_VERSION="1.1.2" # Spécifier une version stable du VPA
kubectl apply -f https://github.com/kubernetes/autoscaler/raw/vertical-pod-autoscaler-${VPA_VERSION}/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml
kubectl apply -f https://github.com/kubernetes/autoscaler/raw/vertical-pod-autoscaler-${VPA_VERSION}/vertical-pod-autoscaler/deploy/vpa-v1-admission-controller-gen.yaml

echo "=== Installation de K3s terminée et VPA installé avec succès ==="