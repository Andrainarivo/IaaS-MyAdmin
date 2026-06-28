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

## Configuration

1. **Navigate to the Terraform directory**:

    ```bash
    cd terraform
    ```

2. **Create a `terraform.tfvars` file**: This file will contain your variable values. **Never commit this file to Git** if it contains sensitive information.

    ```tfvars
    # terraform.tfvars
    project_id = "your-gcp-project-id"
    region     = "us-west1"
    zone       = "us-west1-a"
    k3s_token  = "a-very-long-and-random-secret-token"
    ```

    > **Security Note**: The `k3s_token` is sensitive. For production deployments, use a secret manager or environment variables instead of a plain text file.

## Deployment

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
