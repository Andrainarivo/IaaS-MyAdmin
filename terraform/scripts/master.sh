#!/bin/bash
set -e

echo "=== Début de l'installation du Master K3s ==="
apt-get update && apt-get install -y curl

# Utilisation de la variable d'environnement injectée dynamiquement par SSH
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sh -s - server \
  --node-ip=$(hostname -I | awk '{print $1}') \
  --flannel-backend=vxlan