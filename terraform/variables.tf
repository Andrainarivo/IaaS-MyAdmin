variable "project_id" {
  description = "L'ID unique du projet GCP créé sur la console"
  type        = string
}

variable "region" {
  description = "Région GCP par défaut"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "Zone GCP par défaut"
  type        = string
  default     = "us-west1-a"
}

variable "k3s_token" {
  description = "Token secret pré-partagé pour coupler le Master et les Workers k3s"
  type        = string
  sensitive   = true
}
