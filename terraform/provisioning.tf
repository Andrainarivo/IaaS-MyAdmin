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
# K3s Master Control-Plane Initialization
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
# Core Platform Infrastructure Addons (Metrics Server, VPA)
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
# High-Availability Worker Registration (Parallel Scaled Execution)
# ------------------------------------------------------------------------------
resource "terraform_data" "install_k3s_worker" {
  # The workers will only start joining after the master and its core addons are fully configured.
  depends_on = [terraform_data.install_k3s_addons]

  for_each = { for w in module.instances.worker_instances : w.name => w }

  provisioner "local-exec" {
    command = <<EOT
      echo "=== [1/2] Registering Worker Node: ${each.value.name} ==="
      gcloud compute ssh "${each.value.name}" \
        --tunnel-through-iap \
        --zone="${each.value.zone}" \
        --project="${var.project_id}" \
        --command="export K3S_TOKEN='${var.k3s_token}' MASTER_IP='${module.instances.master_private_ip}'; sudo -E bash -s" < "${path.module}/scripts/worker.sh"
    EOT
  }
}

resource "terraform_data" "label_k3s_workers" {
  for_each = { for w in module.instances.worker_instances : w.name => w }

  depends_on = [terraform_data.install_k3s_worker]

  provisioner "local-exec" {
    command = <<EOT
      echo "=== [1/2] Waiting for registration of ${each.key} on the Master ==="
      
      # Loop until the Master sees the node in 'kubectl get nodes'
      until gcloud compute ssh myadmin-k3s-master \
        --tunnel-through-iap \
        --zone="${var.zone}" \
        --project="${var.project_id}" \
        --command="sudo kubectl get nodes" | grep -q "${each.key}"; do
          echo "Node ${each.key} is not yet visible. Retrying in 5 seconds..."
          sleep 5
      done

      echo "=== [2/2] Applying worker role on ${each.key} ==="
      gcloud compute ssh myadmin-k3s-master \
        --tunnel-through-iap \
        --zone="${var.zone}" \
        --project="${var.project_id}" \
        --command="sudo kubectl label node ${each.key} node-role.kubernetes.io/worker="
    EOT
  }
}