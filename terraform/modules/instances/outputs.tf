output "master_private_ip" {
  value       = google_compute_instance.k3s_master.network_interface[0].network_ip
  description = "L'adresse IP privée du nœud Master K3s"
}

# Sortie de l'IP privée du Worker pour utilisation dans d'autres modules ou scripts
#output "worker_private_ip" {
#  value       = google_compute_instance.k3s_worker.network_interface[0].network_ip
#  description = "L'adresse IP privée du nœud Worker K3s"
#}