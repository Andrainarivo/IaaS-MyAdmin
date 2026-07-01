output "master_private_ip" {
  value       = google_compute_instance.k3s_master.network_interface[0].network_ip
  description = "L'adresse IP privée du nœud Master K3s"
}

output "worker_instances" {
  description = "A list of the K3s worker instances created, with their name and zone."
  value = [
    for instance in google_compute_instance.k3s_worker : {
      name = instance.name
      zone = instance.zone
    }
  ]
}