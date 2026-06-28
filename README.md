# Infrastructure as Service of MyAdmin Application

This project contains all the Infrastructure as Code (IaC) and configurations required to deploy, manage, and scale the [`MyAdmin`](https://github.com/Andrainarivo/MyAdmin) application on Google Cloud Platform (GCP).

The infrastructure is provisioned with **Terraform**, and container orchestration is handled by a lightweight **K3s** cluster. A **Jenkins** virtual machine is also provisioned for Continuous Integration and Continuous Deployment (CI/CD).

---

## Overall Architecture

The architecture is designed to be robust, scalable, and automated.

![Architecture Diagram](docs/architecture.svg)

1. **Google Cloud Platform (GCP)**: The target cloud platform.
2. **Terraform**: The tool used to create and manage the infrastructure on GCP, including:
    * A VPC network and firewall rules.
    * Google Compute Engine (GCE) instances for the Kubernetes cluster.
    * A dedicated VM for the CI/CD server (Jenkins).
    * The necessary Service Accounts and IAM permissions.
3. **K3s (Kubernetes)**: A lightweight Kubernetes cluster installed on the GCE instances.
    * **Master Node**: Manages the cluster's state.
    * **Worker Nodes**: Run the application containers.
4. **Jenkins**: The automation server that will build, test, create the application's Docker image, push it to Google Artifact Registry, and deploy the new version to the K3s cluster.
5. **`MyAdmin` Application**: The application is containerized with Docker and deployed on K3s. It is configured with:
    * A **Deployment** to manage the pods.
    * A **Service** for internal network exposure.
    * An **Ingress** for external access.
    * A **Horizontal Pod Autoscaler (HPA)** for automatic scaling based on CPU load.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured:

* **Google Cloud SDK (`gcloud`)**: Authenticated with an account that has the necessary permissions on your GCP project.
* **Terraform CLI**: To run the provisioning scripts.
* **GCP Authentication for Terraform**: Terraform needs credentials to manage resources. The easiest way for a local run is Application Default Credentials (ADC).

## Project Structure

For a detailed description of each module, please consult the dedicated [documentation](docs/project-structure.md).

## Guide de déploiement

Consultez le [guide de déploiement Terraform](docs/terraform-guide.md) pour les instructions étape par étape sur la création de l'infrastructure.

## Développement local

Pour travailler sur l'application sans déployer toute l'infrastructure, vous pouvez utiliser l'environnement Docker Compose. Consultez le [guide de développement local](docs/local-development.md) pour plus de détails.
