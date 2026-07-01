# ==============================================================================
# 1. Activation of Required GCP APIs
# ==============================================================================

locals {
  required_apis = [
    "compute.googleapis.com",          # Compute Engine API is essential for managing VM instances and networking resources
    "artifactregistry.googleapis.com", # Artifact Registry API is necessary for creating and managing private container registries
    "iam.googleapis.com",              # IAM API is required for Artifact Registry to manage permissions
    "storage.googleapis.com"           # Cloud Storage API is required for the Terraform backend bucket
  ]
}

resource "google_project_service" "gcp_apis" {
  for_each           = toset(local.required_apis)
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# ==============================================================================
# 2. Waiting for API Propagation
# ==============================================================================
# This resource introduces a delay to ensure that the GCP APIs are fully propagated and available before proceeding with the creation of dependent resources, such as the Artifact Registry repository.
# This is particularly important in automated workflows where immediate subsequent API calls may fail if the services are not yet ready.
resource "time_sleep" "wait_for_api_propagation" {
  depends_on = [google_project_service.gcp_apis]

  create_duration = "120s"
}