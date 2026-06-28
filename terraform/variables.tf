variable "project_id" {
  description = "The unique ID of the GCP project created in the console"
  type        = string
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "Default GCP zone"
  type        = string
  default     = "us-west1-a"
}

variable "k3s_token" {
  description = "Pre-shared secret token to join K3s Master and Workers"
  type        = string
  sensitive   = true
}
