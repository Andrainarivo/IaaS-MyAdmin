# Terraform Deployment Guide

This guide explains how to provision the entire infrastructure on Google Cloud Platform using Terraform.

## Prerequisites

1. **GCP Authentication**: Ensure your `gcloud` CLI is installed and authenticated.

    ```bash
    gcloud auth login
    gcloud config set project YOUR_PROJECT_ID
    ```

2. **Terraform Authentication**: Terraform needs to act on your behalf. The simplest method for local execution is to use Application Default Credentials (ADC).

    ```bash
    gcloud auth application-default login
    ```

## Configuration & Setup

To configure the deployment for a new project, run the interactive initialization script from the root of the repository. This is the recommended first step.

```bash
chmod +x ./init-project.sh
./init-project.sh
```

This script will:

- Ask for your new Project ID, region, and zone
- Generate a secure `k3s_token`.
- Automatically create `terraform/terraform.tfvars` with your settings.
- Update the Terraform backend and Jenkinsfile with your project details.
- Create the necessary GCS bucket for storing Terraform state if it doesn't exist.

## Deployment

Once the initialization is complete, navigate to the `terraform` directory:

```bash
cd terraform
```

1. **Initialize**: Initializes the Terraform working directory, downloading the necessary providers.

    ```bash
    terraform init
    ```

2. **Plan**: Shows the actions Terraform will take. This is a crucial verification step.

    ```bash
    terraform plan
    ```

3. **Apply**: Creates the infrastructure. Terraform will ask for confirmation before proceeding.

    ```bash
    terraform apply
    ```

Once finished, Terraform will display output values like IP addresses. The infrastructure, including the K3s cluster and Jenkins VM, will be running on GCP.

## Destruction

To destroy all infrastructure created by Terraform and avoid unnecessary costs:

```bash
terraform destroy
```
