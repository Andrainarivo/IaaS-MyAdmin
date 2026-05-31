# 1. Flux Internes du Cluster k3s (Master <-> Worker)
resource "google_compute_firewall" "allow_internal" {
  name    = "myadmin-fw-allow-internal"
  network = var.network_name

  allow { protocol = "icmp" }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["8472"] # Flannel VXLAN overlay
  }

  source_ranges = ["10.10.10.0/24"]
}

# 2. Accès SSH d'administration sécurisé via GCP IAP et accès d'administration de Jenkins
resource "google_compute_firewall" "allow_ssh" {
  name    = "myadmin-fw-allow-ssh-iap"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  # Plage d'IP officielle de Google utilisée pour le tunnel IAP.
  # Aucune autre IP ne pourra tenter de bruteforce le port 22.
  source_ranges = ["35.235.240.0/20"]
}

# 3. Exposition publique de l'API / Ingress k3s
resource "google_compute_firewall" "allow_public" {
  name    = "myadmin-fw-allow-public"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
}