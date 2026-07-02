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
mkdir -p "${JENKINS_DIR}"
cd "${JENKINS_DIR}"

# 3. Download Dockerfile & docker-compose.yml for Jenkins
# Variables de configuration
GITHUB_USER="Andrainarivo"
REPO_NAME="IaaS-MyAdmin"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}/docker/jenkins"

curl -fsSL "${RAW_BASE_URL}/Dockerfile" -o "${JENKINS_DIR}/Dockerfile"
curl -fsSL "${RAW_BASE_URL}/docker-compose.yml" -o "${JENKINS_DIR}/docker-compose.yml"

echo "=== Configuration files downloaded successfully. Building and starting Jenkins... ==="

# 4. Run Docker Compose in detached mode to build and start Jenkins
docker compose up -d --build

echo "=== Jenkins startup script finished. Jenkins is starting in the background. ==="
echo "=== See logs with: docker logs -f myadmin-jenkins | grep 'initialAdminPassword' to get the password for the initial admin user ==="
echo "=== You can access Jenkins at http://<SERVER_IP>:8080 ==="