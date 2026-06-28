# ==============================================================================
# K3s Cluster Provisioning & Orchestration Lifecycle
# ==============================================================================

# Global synchronization point to ensure all remote virtual machines have fully 
# cycled through initialization and are actively listening on SSH Port 22.
resource "time_sleep" "wait_for_all_vms_boot" {
  depends_on = [module.instances]

  create_duration = "30s"
}

# ------------------------------------------------------------------------------
# Phase 1: K3s Master Control-Plane Initialization
# ------------------------------------------------------------------------------
resource "terraform_data" "install_k3s_master" {
  depends_on = [time_sleep.wait_for_all_vms_boot]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh myadmin-k3s-master \
        --tunnel-through-iap \
        --zone="${var.zone}" \
        --project="${var.project_id}" \
        --command='export K3S_TOKEN="${var.k3s_token}"; sudo -E bash -s' < "${path.module}/scripts/master.sh"
    EOT
  }
}

# ------------------------------------------------------------------------------
# Phase 2: Core Platform Infrastructure Addons (Metrics Server, VPA, Ingress)
# ------------------------------------------------------------------------------
resource "terraform_data" "install_k3s_addons" {
  depends_on = [terraform_data.install_k3s_master]

  # Automated lifecycle trigger: executes updates if the script content shifts
  triggers_replace = [
    md5(file("${path.module}/scripts/addons.sh"))
  ]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh myadmin-k3s-master \
        --tunnel-through-iap \
        --zone="${var.zone}" \
        --project="${var.project_id}" \
        --command='sudo -E bash -s' < "${path.module}/scripts/addons.sh"
    EOT
  }
}

# ------------------------------------------------------------------------------
# Phase 3: High-Availability Worker Registration (Parallel Scaled Execution)
# ------------------------------------------------------------------------------
resource "terraform_data" "install_k3s_worker" {
  # Explicit dependency guarantees the control plane is stable before worker attachment
  depends_on = [
    time_sleep.wait_for_all_vms_boot, 
    terraform_data.install_k3s_master
  ]

  for_each = { for w in module.instances.worker_instances : w.name => w }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh "${each.value.name}" \
        --tunnel-through-iap \
        --zone="${each.value.zone}" \
        --project="${var.project_id}" \
        --command='export K3S_TOKEN="${var.k3s_token}" MASTER_IP="${module.instances.master_private_ip}"; sudo -E bash -s' < "${path.module}/scripts/worker.sh"
    EOT
  }
}