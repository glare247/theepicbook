# ─────────────────────────────────────────────────────────────────
# SECURITY MODULE
#
# Official docs:
# https://cloud.google.com/armor/docs/cloud-armor-overview
# https://cloud.google.com/secret-manager/docs/overview
#
# This module creates:
# 1. Cloud Armor WAF Security Policy
#    - Blocks SQL injection attacks
#    - Blocks XSS attacks
#    - Rate limiting per IP
# 2. GCP Secret Manager secrets
#    - DATABASE_URL
#    - ARGOCD_AUTH_TOKEN
#    - GRAFANA_ADMIN_PASSWORD
#    - SNYK_TOKEN
# 3. Cloud Monitoring
#    - Uptime check
#    - CPU alert policy
#    - Memory alert policy
# ─────────────────────────────────────────────────────────────────

# ── 1. Cloud Armor WAF Security Policy ───────────────────────────
# Sits in front of the Load Balancer
# Protects against common web attacks
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_security_policy
resource "google_compute_security_policy" "waf_policy" {
  name    = "${var.env}-waf-policy"
  project = var.project_id

  description = "CloudOpsHub ${var.env} WAF — rate limiting + SQLi/XSS protection"

  # ── Rule 1: Block SQL Injection ───────────────────────────────
  # Docs: https://cloud.google.com/armor/docs/waf-rules
  rule {
    action   = "deny(403)"
    priority = "1000"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }

    description = "Block SQL injection attacks"
  }

  # ── Rule 2: Block XSS Attacks ────────────────────────────────
  rule {
    action   = "deny(403)"
    priority = "1001"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }

    description = "Block Cross-Site Scripting attacks"
  }

  # ── Rule 3: Rate Limiting ─────────────────────────────────────
  # Blocks IPs that send too many requests
  # Docs: https://cloud.google.com/armor/docs/rate-limiting-overview
  rule {
    action   = "throttle"
    priority = "1002"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = var.rate_limit_threshold
        interval_sec = var.rate_limit_interval_sec
      }
    }

    description = "Rate limit per IP address"
  }

  # ── Rule 4: Default Allow ─────────────────────────────────────
  # Must always be last rule — allows all other traffic
  rule {
    action   = "allow"
    priority = "2147483647"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    description = "Default rule — allow all other traffic"
  }
}

# ── 2. Secret Manager — DATABASE_URL ─────────────────────────────
# Stores MySQL container connection string
# Format: mysql://appuser:password@localhost:3306/theepicbook
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret
resource "google_secret_manager_secret" "database_url" {
  secret_id = "${var.env}-database-url"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# ── 3. Secret Manager — Portainer admin password ─────────────────
# Used by CD pipeline to bootstrap Portainer and call its API
# Docs: https://docs.portainer.io/api/docs
resource "google_secret_manager_secret" "portainer_admin_password" {
  secret_id = "${var.env}-portainer-admin-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# ── 4. Secret Manager — DB credentials ───────────────────────────
# Written by Cloud SQL module; read by VM startup script
resource "google_secret_manager_secret" "db_host" {
  secret_id = "${var.env}-db-host"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.env}-db-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# ── 5. Secret Manager — Alerting credentials ─────────────────────
# Read by VM startup script, written to .env, used by Alertmanager
resource "google_secret_manager_secret" "slack_webhook_url" {
  secret_id = "${var.env}-slack-webhook-url"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "alert_email_to" {
  secret_id = "${var.env}-alert-email-to"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "alert_email_from" {
  secret_id = "${var.env}-alert-email-from"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "alert_smtp_host" {
  secret_id = "${var.env}-alert-smtp-host"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "alert_smtp_user" {
  secret_id = "${var.env}-alert-smtp-user"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret" "alert_smtp_pass" {
  secret_id = "${var.env}-alert-smtp-pass"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

# ── 6. Cloud Monitoring — Uptime Check ───────────────────────────
# Pings the app every 60 seconds
# Alerts if app goes down
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config
# Only create uptime check when a real domain is provided
resource "google_monitoring_uptime_check_config" "http_check" {
  count        = var.app_domain != "localhost" ? 1 : 0
  display_name = "${var.env}-uptime-check"
  project      = var.project_id
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/health"
    port         = "80"
    use_ssl      = false
    validate_ssl = false
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.app_domain
    }
  }
}
# ── 7. Cloud Monitoring — CPU Alert ──────────────────────────────
# Fires when CPU stays above threshold for 5 minutes
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "${var.env}-cpu-high-alert"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "CPU utilization over ${var.cpu_alert_threshold * 100}%"

    condition_threshold {
      filter     = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = var.cpu_alert_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels
}

# ── 8. Cloud Monitoring — Memory Alert ───────────────────────────
# Fires when memory usage is too high
resource "google_monitoring_alert_policy" "memory_alert" {
  display_name = "${var.env}-memory-high-alert"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Memory utilization over ${var.memory_alert_threshold * 100}%"

    condition_threshold {
      filter     = "resource.type=\"gce_instance\" AND metric.type=\"agent.googleapis.com/memory/percent_used\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = var.memory_alert_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels
}