resource "google_compute_network" "vpc_network" {
  name                    = "myadmin-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "myadmin-subnet"
  ip_cidr_range = "10.10.10.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}