# ─────────────────────────────────────────────────────────────────
# LOAD BALANCER MODULE
#
# Official docs:
# https://cloud.google.com/load-balancing/docs/https
#
# This module creates:
# 1. Global Static IP address
# 2. Instance Group — wraps the VM so LB can route to it
# 3. Health Check — LB verifies VM is healthy before sending traffic
# 4. Backend Service — connects LB to VM + attaches Cloud Armor WAF
# 5. URL Map — routes all traffic to backend
# 6. Managed SSL Certificate — Google manages SSL for us
# 7. HTTPS Proxy — terminates SSL
# 8. HTTP Proxy — redirects HTTP to HTTPS
# 9. Forwarding Rules — HTTPS port 443 + HTTP port 80
#
# Traffic flow:
# User → Global IP → Forwarding Rule → HTTPS Proxy
#      → URL Map → Backend Service (WAF attached)
#      → Instance Group → VM → Nginx container → Node.js container
# ─────────────────────────────────────────────────────────────────

# ── 1. Global Static IP ──────────────────────────────────────────
# Fixed public IP for the load balancer
# Point your DNS A record to this IP
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.env}-lb-ip"
  project = var.project_id
}

# ── 2. Instance Group ─────────────────────────────────────────────
# Wraps the GCE VM so the Load Balancer can route traffic to it
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group
resource "google_compute_instance_group" "app_group" {
  name    = "${var.env}-app-group"
  zone    = var.vm_zone
  project = var.project_id

  # Add the VM to this instance group
  instances = [var.vm_self_link]

  # Named port — LB routes traffic to port 80 on the VM
  # This is where Nginx container listens
  named_port {
    name = "http"
    port = 80
  }
}

# ── 3. Health Check ───────────────────────────────────────────────
# LB uses this to verify VM is healthy before sending traffic
# If health check fails → LB stops sending traffic to VM
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check
resource "google_compute_health_check" "http_health" {
  name    = "${var.env}-http-health-check"
  project = var.project_id

  http_health_check {
    port         = 80
    request_path = var.health_check_path
  }

  # Check every 10 seconds
  check_interval_sec = 10
  # Wait 5 seconds for response
  timeout_sec = 5
  # 2 successful checks = healthy
  healthy_threshold = 2
  # 3 failed checks = unhealthy
  unhealthy_threshold = 3
}

# ── 4. Backend Service ────────────────────────────────────────────
# Connects Load Balancer to the VM instance group
# Cloud Armor WAF is attached here
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service
resource "google_compute_backend_service" "app_backend" {
  name                  = "${var.env}-backend-service"
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.http_health.id]
  timeout_sec           = 30

  # Attach Cloud Armor WAF from security module
  # This protects against SQLi, XSS and rate limiting
  security_policy = var.waf_policy_id

  backend {
    group           = google_compute_instance_group.app_group.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# ── 5. URL Map ────────────────────────────────────────────────────
# Routes all incoming traffic to the backend service
# Can be extended later to route /api/* differently
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map
resource "google_compute_url_map" "url_map" {
  name            = "${var.env}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.app_backend.id
}

# ── 6. Managed SSL Certificate ────────────────────────────────────
# Google automatically provisions and renews SSL certificates
# Only created when ssl_domains is not empty
# Docs: https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  count   = length(var.ssl_domains) > 0 ? 1 : 0
  name    = "${var.env}-ssl-cert"
  project = var.project_id

  managed {
    domains = var.ssl_domains
  }
}

# ── 7. HTTPS Target Proxy ─────────────────────────────────────────
# Terminates SSL and forwards to URL map
# Only created when ssl_domains is not empty
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  count   = length(var.ssl_domains) > 0 ? 1 : 0
  name    = "${var.env}-https-proxy"
  project = var.project_id
  url_map = google_compute_url_map.url_map.id

  ssl_certificates = [
    google_compute_managed_ssl_certificate.ssl_cert[0].id
  ]
}

# ── 8. HTTP Target Proxy ──────────────────────────────────────────
# Handles plain HTTP traffic — used in dev where no SSL domain
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.env}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.url_map.id
}

# ── 9. Forwarding Rule — HTTPS port 443 ──────────────────────────
# Routes HTTPS traffic to HTTPS proxy
# Only created when ssl_domains is not empty
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule
resource "google_compute_global_forwarding_rule" "https_rule" {
  count                 = length(var.ssl_domains) > 0 ? 1 : 0
  name                  = "${var.env}-https-forwarding-rule"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy[0].id
  load_balancing_scheme = "EXTERNAL"
}

# ── 10. Forwarding Rule — HTTP port 80 ───────────────────────────
# Routes HTTP traffic to HTTP proxy
# In dev — serves traffic directly on port 80
# In prod — redirects to HTTPS
resource "google_compute_global_forwarding_rule" "http_rule" {
  name                  = "${var.env}-http-forwarding-rule"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL"
}