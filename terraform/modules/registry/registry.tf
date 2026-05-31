resource "google_artifact_registry_repository" "myadmin_repo" {
  location      = var.region
  repository_id = "myadmin-repo"
  description   = "Registre Docker privé pour MyAdminProject"
  format        = "DOCKER"
}