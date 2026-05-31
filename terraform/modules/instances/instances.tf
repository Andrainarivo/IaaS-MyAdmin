# 1. Compte de Service Dédié pour K3s
resource "google_service_account" "k3s_sa" {
  account_id   = "myadmin-k3s-sa"
  display_name = "Compte de service pour les nœuds du cluster k3s"
}

# 2. Lien IAM vers l'Artifact Registry pour K3s
resource "google_project_iam_member" "registry_viewer" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.k3s_sa.email}"
}

# 3. VM MASTER K3s
resource "google_compute_instance" "k3s_master" {
  name         = "myadmin-k3s-master"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {}
  }

  service_account {
    email  = google_service_account.k3s_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["k3s-node"]
}

# 4. VMs WORKER K3s
resource "google_compute_instance" "k3s_worker" {
  name         = "myadmin-k3s-worker"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {}
  }

  service_account {
    email  = google_service_account.k3s_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["k3s-node"]
}

resource "google_compute_instance" "k3s_worker2" {
  name         = "myadmin-k3s-worker2"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {}
  }

  service_account {
    email  = google_service_account.k3s_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["k3s-node"]

}

# =========================================================================
#                   CONFIGURATION DE LA VM JENKINS
# =========================================================================

# 5. Compte de Service Dédié pour la VM Jenkins
resource "google_service_account" "jenkins_sa" {
  account_id   = "myadmin-jenkins-sa"
  display_name = "Service Account pour la VM de Management Jenkins"
}

# 6. Rôles IAM requis pour le pipeline Jenkins via IAP
# Autoriser Jenkins à utiliser IAP pour se connecter aux VMs Compute Engine
resource "google_project_iam_member" "jenkins_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Autoriser Jenkins à voir les instances Compute Engine (pour IAP)
resource "google_project_iam_member" "jenkins_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Autoriser Jenkins à se connecter en SSH aux VMs Compute Engine via IAP
resource "google_project_iam_member" "jenkins_os_login" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Autoriser Jenkins à pousser les images Docker dans l'Artifact Registry
resource "google_project_iam_member" "jenkins_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer" # "writer" pour pouvoir push (K3s n'a que "reader")
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Autoriser Jenkins à gérer les instances (requis pour injecter les clés SSH dans les métadonnées)
resource "google_project_iam_member" "jenkins_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1" # Apporte la permission compute.instances.setMetadata
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Autoriser Jenkins à agir en tant que compte de service K3s (Requis pour l'accès SSH)
resource "google_service_account_iam_member" "jenkins_as_k3s_user" {
  service_account_id = google_service_account.k3s_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# 7. La VM Jenkins
resource "google_compute_instance" "jenkins_ops" {
  name         = "myadmin-ops-jenkins"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # Pas de bloc access_config {} -> Reste privée, accessible uniquement via IAP
  }

  metadata_startup_script = file("${path.root}/scripts/jenkins.sh")

  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  labels = {
    environment = "management"
    role        = "cicd"
  }
}