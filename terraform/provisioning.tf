# Processus d'installation K3s - Séparé de la création des VMs

# Une seule pause globale pour laisser TOUTES les VMs booter en parallèle
resource "time_sleep" "wait_for_all_vms_boot" {
  depends_on = [module.instances]

  # 30 secondes suffisent généralement pour que l'OS charge et que SSHD écoute sur le port 22
  create_duration = "30s"
}

# Installation du Master K3s
resource "terraform_data" "install_k3s_master" {
  # Attend que la pause soit finie pour s'assurer que le Master est prêt à recevoir des commandes SSH
  depends_on = [time_sleep.wait_for_all_vms_boot]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh myadmin-k3s-master \
        --tunnel-through-iap \
        --zone=${var.zone} \
        --project=${var.project_id} \
        --command='export K3S_TOKEN="${var.k3s_token}"; sudo -E bash -s' < ${path.root}/scripts/master.sh
    EOT
  }
}

# Ce bloc va se réexécuter AUTOMATIQUEMENT dès que le script 'addons.sh' est modifié.
resource "terraform_data" "install_k3s_addons" {
  depends_on = [terraform_data.install_k3s_master]

  # Calcule le hash du script. Si le script change, Terraform réexécute ce bloc.
  triggers_replace = [
    md5(file("${path.root}/scripts/addons.sh"))
  ]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh myadmin-k3s-master \
        --tunnel-through-iap \
        --zone=${var.zone} \
        --project=${var.project_id} \
        --command='sudo -E bash -s' < ${path.root}/scripts/addons.sh
    EOT
  }
}

# Installation du premier Worker
resource "terraform_data" "install_k3s_worker" {
  # Attend que la pause soit finie ET que le Master soit totalement prêt
  depends_on = [time_sleep.wait_for_all_vms_boot, terraform_data.install_k3s_master]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh myadmin-k3s-worker \
        --tunnel-through-iap \
        --zone=${var.zone} \
        --project=${var.project_id} \
        --command='export K3S_TOKEN="${var.k3s_token}" MASTER_IP="${module.instances.master_private_ip}"; sudo -E bash -s' < ${path.root}/scripts/worker.sh
    EOT
  }
}

# Installation du deuxième Worker
resource "terraform_data" "install_k3s_worker2" {
  # Attend exactement les mêmes prérequis que le premier Worker
  depends_on = [time_sleep.wait_for_all_vms_boot, terraform_data.install_k3s_master]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh myadmin-k3s-worker2 \
        --tunnel-through-iap \
        --zone=${var.zone} \
        --project=${var.project_id} \
        --command='export K3S_TOKEN="${var.k3s_token}" MASTER_IP="${module.instances.master_private_ip}"; sudo -E bash -s' < ${path.root}/scripts/worker.sh
    EOT
  }
}