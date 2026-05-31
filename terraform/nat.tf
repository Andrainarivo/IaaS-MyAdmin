# 1. Création du Routeur Cloud
resource "google_compute_router" "router" {
  name    = "myadmin-cloud-router"
  region  = var.region
  network = module.networks.vpc_name
}

# 2. Configuration du Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "myadmin-cloud-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY" # Google gère les IPs de sortie
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}