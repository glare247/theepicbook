# ─────────────────────────────────────────────────────────────────
# VPC MODULE
#
# Official docs:
# https://cloud.google.com/vpc/docs/overview
#
# This module creates:
# 1. VPC Network
# 2. Private Subnet
# 3. Cloud Router
# 4. Cloud NAT  ← allows VM to pull images from Artifact Registry
# 5. Firewall — allow internal traffic
# 6. Firewall — allow HTTP/HTTPS from Load Balancer
# 7. Firewall — allow SSH only via Google IAP (zero trust)
# 8. Firewall — allow monitoring ports internally only
# ─────────────────────────────────────────────────────────────────

# ── 1. VPC Network ───────────────────────────────────────────────
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "vpc" {
  name                    = "${var.env}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
  description             = "CloudOpsHub ${var.env} VPC - Terraform managed"
}

# ── 2. Private Subnet ────────────────────────────────────────────
# VM lives here — no direct public internet access
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "private" {
  name                     = "${var.env}-private-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true
}

# ── 3. Cloud Router ──────────────────────────────────────────────
# Required for Cloud NAT to work
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "router" {
  name    = "${var.env}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# ── 4. Cloud NAT ─────────────────────────────────────────────────
# CRITICAL — VM has no external IP but needs to:
# - Pull Docker images from GCP Artifact Registry
# - Download packages during startup
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ── 5. Firewall — Allow Internal Traffic ─────────────────────────
# Allows containers on the VM to talk to each other
# e.g. Nginx → Node.js → MySQL
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.env}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  # Only allow traffic from within the subnet
  source_ranges = [var.subnet_cidr]
  description   = "Allow all internal traffic within the private subnet"
}

# ── 6. Firewall — Allow HTTP/HTTPS ───────────────────────────────
# Allows traffic from Cloud Load Balancer to reach the VM
# 130.211.0.0/22 and 35.191.0.0/16 are GCP Load Balancer IP ranges
# Docs: https://cloud.google.com/load-balancing/docs/health-check-concepts
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.env}-allow-http-https"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  # Public internet + GCP Load Balancer health check ranges
  source_ranges = ["0.0.0.0/0", "130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web"]
  description   = "Allow HTTP/HTTPS from internet and LB health checks"
}

# ── 7. Firewall — Allow SSH via IAP Only ─────────────────────────
# VM has NO public IP — only way to SSH is through Google IAP
# 35.235.240.0/20 is Google IAP's fixed IP range
# Docs: https://cloud.google.com/iap/docs/using-tcp-forwarding
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.env}-allow-iap-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # ONLY Google IAP range — no direct SSH from internet
  source_ranges = ["35.235.240.0/20"]
  description   = "Allow SSH only via Google Identity-Aware Proxy"
}

# ── 8. Firewall — Allow Monitoring Ports Internally ──────────────
# Prometheus, Grafana, Node Exporter, Alertmanager
# These ports must NEVER be exposed to the internet
# Docs: https://cloud.google.com/firewall/docs/firewalls
resource "google_compute_firewall" "allow_monitoring" {
  name    = "${var.env}-allow-monitoring"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    # Prometheus:9090 Grafana:3000 NodeExporter:9100 Alertmanager:9093
    ports = ["9090", "9093", "9100", "3000"]
  }

  # Internal only — subnet traffic only
  source_ranges = [var.subnet_cidr]
  description   = "Allow monitoring stack ports - internal traffic only"
}