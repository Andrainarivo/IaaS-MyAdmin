#!/bin/bash
# Désactiver le mode interactif pour apt
export DEBIAN_FRONTEND=noninteractive

# 1. Nettoyage des anciennes versions potentiellement présentes
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    apt-get remove -y $pkg || true
done

# 2. Configuration du dépôt Docker (Apt Repository)
apt-get update
apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Ajout du dépôt aux sources d'Apt en utilisant les variables système officielles
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Installation des paquets Docker officiels
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Activation et démarrage du service
systemctl enable docker
systemctl start docker