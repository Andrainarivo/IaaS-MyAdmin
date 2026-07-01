# 1. Dedicated Service Account for K3s
resource "google_service_account" "k3s_sa" {
  account_id   = "myadmin-k3s-sa"
  display_name = "Service account for the K3s cluster nodes"
}

# 2. IAM binding to Artifact Registry for K3s
resource "google_project_iam_member" "registry_viewer" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.k3s_sa.email}"
}

# 3. K3s MASTER VM
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

# 4. K3s WORKER VMs
resource "google_compute_instance" "k3s_worker" {
  count        = var.worker_count
  machine_type = var.machine_type
  name         = "myadmin-k3s-worker-${count.index + 1}"
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
#                   JENKINS VM CONFIGURATION
# =========================================================================

# 5. Dedicated Service Account for the Jenkins VM
resource "google_service_account" "jenkins_sa" {
  account_id   = "myadmin-jenkins-sa"
  display_name = "Service Account for the Jenkins Management VM"
}

# 6. Required IAM roles for the Jenkins pipeline via IAP
# Allow Jenkins to use IAP to connect to Compute Engine VMs
resource "google_project_iam_member" "jenkins_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Allow Jenkins to view Compute Engine instances (for IAP)
resource "google_project_iam_member" "jenkins_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Allow Jenkins to SSH into Compute Engine VMs via IAP
resource "google_project_iam_member" "jenkins_os_login" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Allow Jenkins to push Docker images to Artifact Registry
resource "google_project_iam_member" "jenkins_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer" # "writer" to be able to push (K3s only has "reader")
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Allow Jenkins to act as the K3s service account (Required for SSH access)
resource "google_service_account_iam_member" "jenkins_as_k3s_user" {
  service_account_id = google_service_account.k3s_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Allow Jenkins to manage instances (required to inject SSH keys into metadata)
resource "google_project_iam_member" "jenkins_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1" # Provides the compute.instances.setMetadata permission
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# 7. The Jenkins VM
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
    # No access_config {} block -> Stays private, accessible only via IAP
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