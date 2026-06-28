variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "zone" {
  type        = string
  description = "Deployment zone for the instances"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the VMs will be connected"
}

variable "k3s_token" {
  type        = string
  description = "Pre-shared secret token for the cluster"
  sensitive   = true
}

variable "worker_count" {
  type        = number
  description = "The number of K3s worker nodes to create"
  default     = 2
}

variable "machine_type" {
  type        = string
  default     = "e2-small"
  description = "The GCP instance type to use for the cluster nodes"
}

variable "boot_image" {
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
  description = "The OS image to use for the cluster"
}

variable "disk_size_gb" {
  type        = number
  default     = 20
  description = "The size of the boot disk in GB"
}