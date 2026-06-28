# K3s installation process - separated from VM creation for clarity.

# A single global pause to let ALL VMs boot in parallel.
resource "time_sleep" "wait_for_all_vms_boot" {
  depends_on = [module.instances]

  # 30 seconds is usually enough for the OS to load and for SSHD to listen on port 22.
  create_duration = "30s"
}

# Installation du Master K3s
resource "terraform_data" "install_k3s_master" {
  # Waits for the sleep to finish to ensure the Master is ready for SSH commands.
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

# This block will re-run AUTOMATICALLY whenever the 'addons.sh' script is modified.
# NOTE: The VPA is already installed in master.sh. This step is redundant but kept for demonstration.
# For production, consider removing this resource and the addons.sh script.
resource "terraform_data" "install_k3s_addons" {
  depends_on = [terraform_data.install_k3s_master]

  # Calculates the script's hash. If the script changes, Terraform re-runs this block.
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

# Installation of K3s workers, dynamically using for_each.
resource "terraform_data" "install_k3s_worker" {
  # Waits for the boot pause AND for the master to be fully provisioned.
  depends_on = [time_sleep.wait_for_all_vms_boot, terraform_data.install_k3s_master]

  # This will run the provisioner for each worker instance defined in the 'instances' module.
  # We assume the module outputs a map of worker objects, e.g., module.instances.worker_instances.
  for_each = { for w in module.instances.worker_instances : w.name => w }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${each.value.name} \
        --tunnel-through-iap \
        --zone=${each.value.zone} \
        --project=${var.project_id} \
        --command='export K3S_TOKEN="${var.k3s_token}" MASTER_IP="${module.instances.master_private_ip}"; sudo -E bash -s' < ${path.root}/scripts/worker.sh
    EOT
  }
}