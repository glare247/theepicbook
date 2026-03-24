# ─────────────────────────────────────────────────────────────────
# CLOUD SQL MODULE — OUTPUTS
# ─────────────────────────────────────────────────────────────────

output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Cloud SQL connection name — format: project:region:instance"
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip" {
  description = "Cloud SQL private IP address — only reachable within the VPC"
  value       = google_sql_database_instance.main.private_ip_address
}

output "db_host_secret_id" {
  description = "Secret Manager secret ID for the DB host (private IP)"
  value       = google_secret_manager_secret.db_host.secret_id
}

output "db_password_secret_id" {
  description = "Secret Manager secret ID for the DB password"
  value       = google_secret_manager_secret.db_password.secret_id
}
