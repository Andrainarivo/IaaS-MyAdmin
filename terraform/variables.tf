variable "project_id" {
  description = "The GCP project ID to deploy resources into."
  type        = string
}

variable "region" {
  description = "The GCP region for resources."
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "The GCP zone for VM instances."
  type        = string
  default     = "us-west1-a"
}

variable "k3s_token" {
  description = "Pre-shared secret token to join K3s Master and Workers"
  type        = string
  sensitive   = true
}