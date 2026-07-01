#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration Files ---
TFVARS_FILE="terraform/terraform.tfvars"
BACKEND_FILE="terraform/backend.tf"
JENKINSFILE="Jenkinsfile.groovy"

echo "############################################################"
echo "### MyAdmin Infrastructure Initializer for New Project ###"
echo "############################################################"
echo
echo "This script will guide you through setting up the necessary"
echo "configuration to deploy the infrastructure to a new GCP project."
echo

# --- Gather User Input ---
read -p "Enter your new GCP Project ID: " GCP_PROJECT_ID
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "Setting GCP Project ID to current project in gcloud config."
    GCP_PROJECT_ID=$(gcloud config get project)
fi

read -p "Enter the GCP Region (e.g., us-west1) [us-west1]: " GCP_REGION
GCP_REGION=${GCP_REGION:-us-west1}

read -p "Enter the GCP Zone (e.g., us-west1-a) [us-west1-a]: " GCP_ZONE
GCP_ZONE=${GCP_ZONE:-us-west1-a}

# Generate a random token for K3s for better security
K3S_TOKEN_DEFAULT=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
read -p "Enter a secret token for K3s [$K3S_TOKEN_DEFAULT]: " K3S_TOKEN
K3S_TOKEN=${K3S_TOKEN:-$K3S_TOKEN_DEFAULT}

echo
echo "Configuration files will be updated with the following values:"
echo "----------------------------------"
echo "Project ID:   $GCP_PROJECT_ID"
echo "Region:       $GCP_REGION"
echo "Zone:         $GCP_ZONE"
echo "----------------------------------"
echo

read -p "Do you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Initialization cancelled."
    exit 1
fi

# --- 1. Create/Update Terraform Variables File ---
echo "-> Creating/updating ${TFVARS_FILE}..."
cat > "$TFVARS_FILE" << EOL
project_id = "$GCP_PROJECT_ID"
region     = "$GCP_REGION"
zone       = "$GCP_ZONE"
k3s_token  = "$K3S_TOKEN"
EOL
echo "Done."

# --- 2. Update Terraform Backend Configuration ---
TFSTATE_BUCKET="myadmin-tfstate-${GCP_PROJECT_ID}"
echo "-> Updating Terraform backend bucket in ${BACKEND_FILE} to '${TFSTATE_BUCKET}'..."
sed -i "s/bucket = \".*\"/bucket = \"${TFSTATE_BUCKET}\"/" "$BACKEND_FILE"
echo "Done."

# --- 3. Update Jenkinsfile Default Parameters ---
echo "-> Updating default parameters in ${JENKINSFILE}..."
# Use robust sed with extended regex to replace values regardless of their current default
sed -i -E "s/(string\(name: 'GCP_PROJECT', defaultValue: ')[^']*/\1${GCP_PROJECT_ID}/" "$JENKINSFILE"
sed -i -E "s/(string\(name: 'GCP_REGION', defaultValue: ')[^']*/\1${GCP_REGION}/" "$JENKINSFILE"
sed -i -E "s/(string\(name: 'GCP_ZONE', defaultValue: ')[^']*/\1${GCP_ZONE}/" "$JENKINSFILE"
echo "Done."

# --- 4. Check and Create GCS Backend Bucket ---
echo "-> Checking for GCS backend bucket: gs://${TFSTATE_BUCKET}"
if gcloud storage buckets describe "gs://${TFSTATE_BUCKET}" --project="${GCP_PROJECT_ID}" >/dev/null 2>&1; then
    echo "Bucket already exists. Skipping creation."
else
    echo "Bucket not found. Creating it now..."
    gcloud storage buckets create "gs://${TFSTATE_BUCKET}" \
        --project="${GCP_PROJECT_ID}" \
        --location="${GCP_REGION}" \
        --uniform-bucket-level-access

    echo "Enabling versioning on the bucket for safety..."
    gcloud storage buckets update "gs://${TFSTATE_BUCKET}" --versioning

    echo "GCS bucket created and configured successfully."
fi

echo
echo "############################################################"
echo "### Initialization Complete! ###"
echo "############################################################"
echo
echo "Next steps:"
echo "1. Navigate to the terraform directory: cd terraform"
echo "2. Initialize Terraform with the new backend: terraform init"
echo "3. Deploy your infrastructure: terraform apply"
echo