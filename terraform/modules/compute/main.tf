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
#      * Prometheus           (port 9090)
#      * Grafana              (port 3000)
#      * Node Exporter        (port 9100)
#      * Alertmanager         (port 9093)
#    - Database: Cloud SQL (managed MySQL — no container needed)
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
  # Installs docker-compose, creates app directories, and writes
  # the .env file used by docker-compose for Cloud SQL credentials
  #
  # IMPORTANT — COS filesystem layout:
  # Container-Optimised OS has a READ-ONLY root filesystem.
  # Only these paths are writable:
  #   /var                       — general writable area
  #   /home                      — user home directories
  #   /tmp                       — ephemeral (lost on reboot)
  #   /mnt/stateful_partition    — persistent across reboots (preferred)
  # /usr, /opt, /usr/local/bin are all READ-ONLY on COS.
  #
  # Docs: https://cloud.google.com/compute/docs/instances/startup-scripts/linux
  # COS docs: https://cloud.google.com/container-optimized-os/docs/concepts/disks-and-filesystem
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = <<-EOF
      #!/bin/bash
      set -e

      echo "=== CloudOpsHub VM Startup Script ==="

      # ── Install docker-compose ───────────────────────────────────
      # Docker is pre-installed on COS — only Compose is missing.
      # /usr/local/bin is read-only on COS → install to /var/bin instead
      # -f flag makes curl fail loudly on HTTP errors (4xx/5xx)
      mkdir -p /var/bin
      curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
        -o /var/bin/docker-compose
      chmod +x /var/bin/docker-compose
      /var/bin/docker-compose version

      export PATH="/var/bin:$PATH"

      # ── Clone or update application repo ─────────────────────────
      # /mnt/stateful_partition persists across reboots on COS
      # /opt is read-only on COS → use /mnt/stateful_partition instead
      # Clone on first boot; skip if already present (e.g. VM restart)
      REPO=/mnt/stateful_partition/cloudopshub
      if [ ! -d "$REPO/.git" ]; then
        git clone https://github.com/glare247/theepicbook.git "$REPO"
      else
        git -C "$REPO" pull origin main
      fi

      # ── Fetch Cloud SQL credentials from Secret Manager ──────────
      # Retry up to 5 times — IAM propagation can take ~60 seconds
      echo "Fetching DB credentials from Secret Manager..."
      for i in $(seq 1 5); do
        DB_HOST=$(gcloud secrets versions access latest \
          --secret="${var.env}-db-host" \
          --project="${var.project_id}" 2>/dev/null) && break
        echo "Attempt $${i}: Secret not ready yet, retrying in 15s..."
        sleep 15
      done

      DB_PASSWORD=$(gcloud secrets versions access latest \
        --secret="${var.env}-db-password" \
        --project="${var.project_id}" 2>/dev/null || echo "")

      # ── Fetch alerting credentials from Secret Manager ───────────
      SLACK_WEBHOOK_URL=$(gcloud secrets versions access latest \
        --secret="${var.env}-slack-webhook-url" \
        --project="${var.project_id}" 2>/dev/null || echo "")

      ALERTMANAGER_EMAIL_TO=$(gcloud secrets versions access latest \
        --secret="${var.env}-alert-email-to" \
        --project="${var.project_id}" 2>/dev/null || echo "")

      ALERTMANAGER_EMAIL_FROM=$(gcloud secrets versions access latest \
        --secret="${var.env}-alert-email-from" \
        --project="${var.project_id}" 2>/dev/null || echo "alerts@cloudopshub.com")

      ALERTMANAGER_SMTP_HOST=$(gcloud secrets versions access latest \
        --secret="${var.env}-alert-smtp-host" \
        --project="${var.project_id}" 2>/dev/null || echo "smtp.gmail.com:587")

      ALERTMANAGER_SMTP_USER=$(gcloud secrets versions access latest \
        --secret="${var.env}-alert-smtp-user" \
        --project="${var.project_id}" 2>/dev/null || echo "")

      ALERTMANAGER_SMTP_PASS=$(gcloud secrets versions access latest \
        --secret="${var.env}-alert-smtp-pass" \
        --project="${var.project_id}" 2>/dev/null || echo "")

      # ── Write .env file for docker-compose ──────────────────────
      # docker-compose reads this via: env_file: /mnt/stateful_partition/cloudopshub/.env
      # Contains DB credentials + alerting credentials
      cat > /mnt/stateful_partition/cloudopshub/.env <<-ENVFILE
DB_HOST=$${DB_HOST}
DB_USER=appuser
DB_PASSWORD=$${DB_PASSWORD}
DB_NAME=bookstore
SLACK_WEBHOOK_URL=$${SLACK_WEBHOOK_URL}
ALERTMANAGER_EMAIL_TO=$${ALERTMANAGER_EMAIL_TO}
ALERTMANAGER_EMAIL_FROM=$${ALERTMANAGER_EMAIL_FROM}
ALERTMANAGER_SMTP_HOST=$${ALERTMANAGER_SMTP_HOST}
ALERTMANAGER_SMTP_USER=$${ALERTMANAGER_SMTP_USER}
ALERTMANAGER_SMTP_PASS=$${ALERTMANAGER_SMTP_PASS}
ENVFILE

      # Restrict permissions — only root can read the credentials
      chmod 600 /mnt/stateful_partition/cloudopshub/.env

      echo "=== Startup Complete — Environment configured ==="
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