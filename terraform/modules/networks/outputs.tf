output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "vpc_id" {
  value = google_compute_network.vpc_network.id
}

