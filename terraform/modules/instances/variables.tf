variable "project_id" {
  type        = string
  description = "ID du projet GCP"
}

variable "zone" {
  type        = string
  description = "Zone de déploiement des instances"
}

variable "subnet_id" {
  type        = string
  description = "ID du sous-réseau où connecter les VMs"
}

variable "k3s_token" {
  type        = string
  description = "Token secret pré-partagé pour le cluster"
  sensitive   = true
}

variable "machine_type" {
  type        = string
  default     = "e2-small"
  description = "Le type d'instance GCP à utiliser pour les nœuds du cluster"
}

variable "boot_image" {
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
  description = "L'image de l'OS à utiliser pour le cluster"
}

variable "disk_size_gb" {
  type        = number
  default     = 20
  description = "La taille du disque de démarrage en Go"
}