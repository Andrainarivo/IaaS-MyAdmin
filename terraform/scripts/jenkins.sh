#!/bin/bash
# Disable interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# 1. Clean up any potentially old versions
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    apt-get remove -y $pkg || true
done

# 2. Set up the Docker repository (Apt Repository)
apt-get update
apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources using official system variables
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Install the official Docker packages
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Enable and start the service
systemctl enable docker
systemctl start docker

echo "=== Docker and Docker Compose installed successfully ==="

# 2. Create directory for Jenkins configuration
JENKINS_DIR="/opt/myadmin-jenkins"
mkdir -p "${JENKINS_DIR}/jenkins_config"
cd "${JENKINS_DIR}"

# 3. Create Dockerfile for Jenkins (from your project)
cat <<EOF > "${JENKINS_DIR}/jenkins_config/Dockerfile"
FROM jenkins/jenkins:lts-jdk17

USER root

# 1. Installation du CLI Docker via le dépôt officiel Debian
RUN apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Installation du SDK gcloud pour Debian
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list

# 3. Installation des paquets officiels et nettoyage des caches
RUN apt-get update && apt-get install -y \
    docker-ce-cli \
    google-cloud-cli \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER jenkins
EOF

# 4. Create docker-compose.yml (from your project)
cat <<EOF > "${JENKINS_DIR}/docker-compose.yml"
networks:
  jenkins-net:
    name: jenkins-net

volumes:
  jenkins-data:
    name: jenkins-data
  jenkins-docker-certs:
    name: jenkins-docker-certs

services:
  # 1. The Docker Sidecar (DinD) - Provides a secure Docker environment for Jenkins
  docker-dind:
    image: docker:dind
    container_name: jenkins-docker
    privileged: true
    restart: unless-stopped
    networks:
      jenkins-net:
        aliases:
          - docker
    environment:
      - DOCKER_TLS_CERTDIR=/certs
    volumes:
      - jenkins-docker-certs:/certs/client
      - jenkins-data:/var/jenkins_home
    command: --storage-driver overlay2

  # 2. The Jenkins Controller - Manages CI/CD jobs and interacts with the Docker Sidecar
  jenkins:
    build: .
    container_name: myadmin-jenkins
    restart: unless-stopped
    networks:
      - jenkins-net
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      - DOCKER_HOST=tcp://docker:2376
      - DOCKER_TLS_VERIFY=1
      - DOCKER_CERT_PATH=/certs/client
    volumes:
      - jenkins-data:/var/jenkins_home
      - jenkins-docker-certs:/certs/client:ro
    depends_on:
      - docker-dind
EOF

echo "=== Configuration files created. Building and starting Jenkins... ==="

# 5. Run Docker Compose in detached mode to build and start Jenkins
docker compose up -d --build

echo "=== Jenkins startup script finished. Jenkins is starting in the background. ==="
echo "=== See logs with: docker logs -f myadmin-jenkins | grep 'initialAdminPassword' to get the password for the initial admin user ==="
echo "=== You can access Jenkins at http://<SERVER_IP>:8080 ==="