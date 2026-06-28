# Project Structure

This document details the structure of the `IaaS-MyAdmin` project and the role of each component.

## Directory Tree

```text
IaaS-MyAdmin/
├── docs/
│   ├── local-development.md
│   ├── project-structure.md
│   └── terraform-guide.md
├── docker/
│   └── api/
│       └── docker-compose.yml
│   └── jenkins/
├── k3s/
│   ├── hpa.yaml
│   └── myadmin.yaml
│   └── ...
└── terraform/
    ├── modules/
    │   └── firewalls/
    │   └── instances/
    │   └── networks/
    │   └── registry/
    ├── scripts/
    │   ├── addons.sh
    │   └── jenkins.sh
    │   └── master.sh
    │   └── worker.sh
    ├── provisioning.tf
    └── variables.tf
```

---

### `docs/` Directory

Contains all project documentation.

- `project-structure.md`: This file.
- `terraform-guide.md`: Instructions for deploying the infrastructure with Terraform.
- `local-development.md`: Guide for running the local development environment.

### `docker/` Directory

Contains configurations for running the application locally.

- `docker/api/docker-compose.yml`: Defines the `api` and `db` (MySQL) services for a rapid development environment. It manages volumes, environment variables, and service dependencies.

### `k3s/` Directory

Contains the Kubernetes manifests for deploying the `MyAdmin` application on the cluster.

- `myadmin.yaml`: Defines three essential Kubernetes objects:
  - **Deployment**: Describes the desired state of the application (image, number of replicas, resources, environment variables).
  - **Service**: Exposes the Deployment internally within the cluster via a `ClusterIP`.
  - **Ingress**: Manages external access to the Service, allowing HTTP traffic to reach the application.
- `hpa.yaml`: Defines a `HorizontalPodAutoscaler` that automatically adjusts the number of pods in the `Deployment` based on CPU usage.

### `terraform/` Directory

Contains all the Infrastructure as Code (IaC) to provision the environment on GCP.

- `provisioning.tf`: Orchestrates the execution of provisioning scripts on the VMs after their creation. It uses `local-exec` to connect via SSH through IAP and install K3s.
- `variables.tf`: Defines the global variables for the Terraform project (project ID, region, etc.).
- `modules/instances/`: A reusable Terraform module for creating GCP instances (master, workers, Jenkins) as well as the associated service accounts and IAM permissions.
- `scripts/`: Shell scripts executed by Terraform provisioners.
  - `master.sh`: Installation script for the K3s master node.
  - `worker.sh` (not provided): Installation script for the K3s worker nodes.
  - `addons.sh`: Script to install additional components like the Vertical Pod Autoscaler (VPA).
