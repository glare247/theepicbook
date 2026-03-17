# ─────────────────────────────────────────────────────────────────
# COMPUTE MODULE
#
# Official docs:
# https://cloud.google.com/compute/docs/instances
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
#
# This module creates:
# 1. GCE VM — Container-Optimised OS
#    - No external IP (matches architecture diagram)
#    - Accessed only via Cloud IAP
#    - Runs all Docker containers:
#      * theepicbook-frontend (Nginx port 80)
#      * theepicbook-backend  (Node.js port 8080)
#      * theepicbook-mysql    (MySQL port 3306)
#      * Prometheus           (port 9090)
#      * Grafana              (port 3000)
#      * Node Exporter        (port 9100)
#      * Alertmanager         (port 9093)
# ─────────────────────────────────────────────────────────────────

resource "google_compute_instance" "app_vm" {
  name         = "${var.env}-app-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  # Tags link this VM to firewall rules
  # "web" tag → allows HTTP/HTTPS traffic
  # env tag   → environment-specific rules
  tags = ["web", var.env]

  boot_disk {
    initialize_params {
      # Container-Optimised OS — Docker pre-installed
      # Minimal attack surface — only Docker runs on this OS
      # Docs: https://cloud.google.com/container-optimized-os/docs
      image = "cos-cloud/cos-stable"
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # NO access_config block = NO external IP
    # Matches architecture diagram: "no external IP"
    # VM can only be reached via:
    # - Cloud IAP (admin SSH access)
    # - Cloud Load Balancer (web traffic)
    # - Internal subnet traffic
  }

  # Startup script runs once when VM boots
  # Installs docker-compose and creates app directories
  # Docs: https://cloud.google.com/compute/docs/instances/startup-scripts/linux
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = <<-EOF
      #!/bin/bash
      set -e

      echo "=== CloudOpsHub VM Startup Script ==="

      # Install docker-compose
      # Docker is pre-installed on Container-Optimised OS
      curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
        -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose

      # Create application directories
      mkdir -p /opt/cloudopshub/app
      mkdir -p /opt/cloudopshub/monitoring
      mkdir -p /opt/cloudopshub/mysql/data
      mkdir -p /opt/cloudopshub/nginx

      echo "=== Startup Complete — Ready for ArgoCD deployment ==="
    EOF
  }

  # Attach the VM service account
  # This is how the VM authenticates to GCP APIs — no static keys
  # Docs: https://cloud.google.com/compute/docs/access/service-accounts
  service_account {
    email = var.vm_sa_email
    # cloud-platform scope — full GCP API access
    # Controlled by IAM roles on the service account
    scopes = ["cloud-platform"]
  }

  labels = var.labels

  # Ensure VM is recreated if startup script changes
  lifecycle {
    create_before_destroy = true
  }
}