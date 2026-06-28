# Technical Cheatsheet

This document provides a collection of common command-line interface (CLI) commands for interacting with the deployed infrastructure.

## 1. Connecting to the K3s Cluster

To manage the Kubernetes cluster from your local machine, you need the `kubeconfig` file. This process involves securely copying the file from the master node and setting up a secure tunnel.

### Step 1: Set Environment Variables

These variables will make the following commands easier to copy-paste.

```bash
export GCLOUD_PROJECT=$(gcloud config get-value project)
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

In a **different terminal**, use `gcloud` to copy the `k3s.yaml` file from the master node.

```bash
gcloud compute scp myadmin-k3s-master:/etc/rancher/k3s/k3s.yaml ./k3s.yaml \
  --project=${GCLOUD_PROJECT} \
  --zone=${GCLOUD_ZONE} \
  --tunnel-through-iap
```

Now, modify the downloaded `k3s.yaml` to point to your local tunnel instead of the master's internal address.

```bash
# For macOS/BSD:
sed -i '' 's/server: https:\/\/127.0.0.1:6443/server: https:\/\/127.0.0.1:6443/' k3s.yaml
sed -i '' 's/server: https:\/\/[0-9\.]*:6443/server: https:\/\/127.0.0.1:6443/' k3s.yaml

# For Linux (GNU sed):
sed -i 's/server: https:\/\/[0-9\.]*:6443/server: https:\/\/127.0.0.1:6443/' k3s.yaml
```

### Step 4: Use Kubectl

You can now interact with your cluster using `kubectl` by pointing it to your modified config file.

```bash
export KUBECONFIG=./k3s.yaml

# Test the connection
kubectl get nodes
# EXPECTED OUTPUT:
# NAME                 STATUS   ROLES                  AGE   VERSION
# myadmin-k3s-master   Ready    control-plane,master   ...   v1.2x.x+k3s1
# myadmin-k3s-worker   Ready    <none>                 ...   v1.2x.x+k3s1
# myadmin-k3s-worker2  Ready    <none>                 ...   v1.2x.x+k3s1
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

# Apply changes from a manifest file
kubectl apply -f k3s/myadmin.yaml
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
