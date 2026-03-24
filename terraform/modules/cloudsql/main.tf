# ─────────────────────────────────────────────────────────────────
# CLOUD SQL MODULE
#
# Official docs:
# https://cloud.google.com/sql/docs/mysql
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance
#
# This module creates:
# 1. Random password for the app DB user
# 2. Cloud SQL MySQL 8.0 instance with private IP
# 3. bookstore database
# 4. appuser (non-root DB user)
# 5. Secret Manager secrets — db-host and db-password
# 6. IAM — VM SA gets Cloud SQL client role
#
# Connection model: private IP within VPC (no proxy needed)
# The VM and Cloud SQL share the same VPC via Private Service Access
# which is set up in the VPC module.
# ─────────────────────────────────────────────────────────────────

# ── 1. Random password ───────────────────────────────────────────
# Generates a strong 24-char password for the DB app user
# Stored in Secret Manager — never hardcoded anywhere
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

# ── 2. Cloud SQL Instance ────────────────────────────────────────
# MySQL 8.0 on private IP — no public IP
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance
resource "google_sql_database_instance" "main" {
  name             = "${var.env}-db"
  project          = var.project_id
  region           = var.region
  database_version = "MYSQL_8_0"

  # Protect prod from accidental terraform destroy
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.db_tier
    availability_type = var.availability_type
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true

    # ── Backups ──────────────────────────────────────────────────
    # Binary log enables point-in-time recovery
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "02:00"

      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    # ── Private IP ───────────────────────────────────────────────
    # No public IP — reachable only within the VPC
    # requires Private Service Access set up in the VPC module
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_self_link

      # Allow unencrypted on private network — VPC is the security perimeter
      # The app (Sequelize) does not need SSL config changes
      ssl_mode = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }

    # ── Maintenance ──────────────────────────────────────────────
    # Sunday 03:00 — lowest traffic window
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    # ── Query Insights ───────────────────────────────────────────
    # Enables slow query analysis in Cloud Console
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
    }

    user_labels = var.labels
  }

  # Ensures Private Service Access connection exists before instance
  depends_on = [var.private_vpc_connection_id]
}

# ── 3. Database ──────────────────────────────────────────────────
resource "google_sql_database" "bookstore" {
  name     = "bookstore"
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  charset  = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

# ── 4. App User ──────────────────────────────────────────────────
# Uses random password — NOT root credentials
# Follows least-privilege: app user owns only bookstore DB
resource "google_sql_user" "app_user" {
  name     = "appuser"
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  password = random_password.db_password.result
  host     = "%"
}

# ── 5a. Secret — DB Host (private IP) ───────────────────────────
# Startup script reads this to set DB_HOST in the VM's .env file
resource "google_secret_manager_secret" "db_host" {
  secret_id = "${var.env}-db-host"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_host" {
  secret      = google_secret_manager_secret.db_host.id
  secret_data = google_sql_database_instance.main.private_ip_address
}

# ── 5b. Secret — DB Password ─────────────────────────────────────
# Startup script reads this to set DB_PASSWORD in the VM's .env file
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.env}-db-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Note: roles/cloudsql.client is granted to the VM SA in the serviceaccounts module
# which is the canonical place for all VM SA IAM grants.
