# Technical Cheatsheet

This document provides a collection of common command-line interface (CLI) commands for interacting with the deployed infrastructure.

## 1. Connecting to the K3s Cluster

To manage the Kubernetes cluster from your local machine, you need the `kubeconfig` file. This process involves securely copying the file from the master node and setting up a secure tunnel.

### Step 1: Set Environment Variables

These variables will make the following commands easier to copy-paste.

```bash
export GCLOUD_PROJECT=$(gcloud config get project)
export GCLOUD_ZONE="us-west1-a" # Or the zone you deployed to
```

### Step 2: Start a Secure Tunnel to the Master Node

The K3s API server is not exposed to the public internet. We will use `gcloud` to create an SSH tunnel through IAP (Identity-Aware Proxy), forwarding the cluster's API server port (6443) to your local machine.

**Open a new, dedicated terminal window** and run this command. It will run in the foreground, keeping the tunnel open.

```bash
gcloud compute ssh myadmin-k3s-master \
  --project=${GCLOUD_PROJECT} \
  --zone=${GCLOUD_ZONE} \
  --tunnel-through-iap \
  -- -L 6443:127.0.0.1:6443
```

### Step 3: Fetch and Modify the Kubeconfig

In a **different terminal**, use `gcloud ssh` to read the `k3s.yaml` file from the master node (which requires `sudo`) and save it locally. The `scp` command fails due to file permissions, as the file is owned by `root`.

```bash
gcloud compute ssh myadmin-k3s-master \
  --project=${GCLOUD_PROJECT} \
  --zone=${GCLOUD_ZONE} \
  --tunnel-through-iap \
  --command="sudo cat /etc/rancher/k3s/k3s.yaml" > k3s.yaml
```

Now, modify the downloaded `k3s.yaml` to point to your local tunnel instead of the master's internal address.

```bash
sed -i 's/server: https:\/\/[0-9\.]*:6443/server: https:\/\/127.0.0.1:6443/' k3s.yaml
```

### Step 4: Use Kubectl

You can now interact with your cluster using `kubectl` by pointing it to your modified config file.

```bash
export KUBECONFIG=./k3s.yaml

# Test the connection
kubectl get nodes -o wide
```

```stdout
# EXPECTED OUTPUT:
NAME                  STATUS   ROLES           AGE   VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
myadmin-k3s-master    Ready    control-plane   35d   v1.35.5+k3s1   10.10.10.X    <none>        Ubuntu 22.04.5 LTS   6.8.0-1058-gcp   containerd://2.2.3-k3s1
myadmin-k3s-worker    Ready    worker          35d   v1.35.5+k3s1   10.10.10.Y    <none>        Ubuntu 22.04.5 LTS   6.8.0-1058-gcp   containerd://2.2.3-k3s1
myadmin-k3s-worker2   Ready    worker          32d   v1.35.5+k3s1   10.10.10.Z    <none>        Ubuntu 22.04.5 LTS   6.8.0-1058-gcp   containerd://2.2.3-k3s1
```

## 2. Kubectl Commands

All commands should specify the namespace with `-n myadmin-dev`.

### Application Management

```bash
# List running pods for the application
kubectl get pods -n myadmin-dev

# View logs for a specific pod
POD_NAME=$(kubectl get pods -n myadmin-dev -l app.kubernetes.io/name=myadmin-api -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME -n myadmin-dev

# Get detailed information about the deployment
kubectl describe deployment myadmin-api -n myadmin-dev

# Stream live runtime log outputs from the core application containers
kubectl logs deployment/myadmin-api --container=myadmin-core -f -n myadmin-dev

# Apply targeted manifest configurations manually to the development namespace
kubectl apply -f k3s/myadmin.yaml -n myadmin-dev

# Inspect the deployment change log and version history
kubectl rollout history deployment/myadmin-api -n myadmin-dev

# Revert a bad deployment instantly to the last stable configuration
kubectl rollout undo deployment/myadmin-api -n myadmin-dev
```

### Autoscaling (HPA & VPA)

```bash
# Check the status of the Horizontal Pod Autoscaler
kubectl get hpa -n myadmin-dev

# Get detailed information and events for the HPA
kubectl describe hpa myadmin-api-hpa -n myadmin-dev

# Check the status of the Vertical Pod Autoscaler for your app
# Note: A VPA object must be created for the deployment first. The 'addons.sh' script only installs the VPA components.
kubectl get vpa -n myadmin-dev
```

### Manual Token Refreshes

If a cluster scaling event occurs while a token is stale or invalid, administrators can bypass the 30-minute schedule and force an immediate token refresh by creating a one-off job from the template:

```bash
kubectl create job --from=cronjob/gar-token-refresher manual-token-refresh -n myadmin-dev
```

## 3. GCloud Commands

These are useful for direct interaction with the VMs.

```bash
# SSH into the Jenkins VM
gcloud compute ssh myadmin-jenkins --project=${GCLOUD_PROJECT} --zone=${GCLOUD_ZONE} --tunnel-through-iap

# Copy a local file to the master node's home directory
gcloud compute scp ./local-file.txt myadmin-k3s-master:~/ --project=${GCLOUD_PROJECT} --zone=${GCLOUD_ZONE} --tunnel-through-iap
```

## 4. Jenkins CLI (Example Usage)

Once Jenkins is fully configured on its VM, you would typically use its CLI to manage jobs.

1. **Download the CLI client** from your Jenkins server (`http://<JENKINS_IP>:8080/jnlpJars/jenkins-cli.jar`).
2. **Authenticate** (e.g., with an API token).

```bash
# Example: Trigger a build for a pipeline named 'myadmin-api-pipeline'
java -jar jenkins-cli.jar -s http://<JENKINS_IP>:8080/ -auth @jenkins_token build myadmin-api-pipeline -s

# Example: List all jobs
java -jar jenkins-cli.jar -s http://<JENKINS_IP>:8080/ -auth @jenkins_token list-jobs
```

> **Note**: The Jenkins instance provisioned by this project is a blank slate. You must configure it, create jobs (e.g., a `Jenkinsfile` in your app repository), and set up credentials before these commands will work.
