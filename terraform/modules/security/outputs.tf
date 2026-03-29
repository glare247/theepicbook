# ─────────────────────────────────────────────────────────────────
# SECURITY MODULE — OUTPUTS
#
# These values are passed to other modules:
# waf_policy_id → loadbalancer module (attached to backend service)
# secret IDs    → referenced in startup scripts and CD pipeline
# ─────────────────────────────────────────────────────────────────

output "waf_policy_id" {
  description = "Cloud Armor WAF policy ID — attached to load balancer"
  value       = google_compute_security_policy.waf_policy.id
}

output "waf_policy_name" {
  description = "Cloud Armor WAF policy name"
  value       = google_compute_security_policy.waf_policy.name
}

output "database_url_secret_id" {
  description = "Secret Manager secret ID for database URL"
  value       = google_secret_manager_secret.database_url.secret_id
}

output "portainer_admin_password_secret_id" {
  description = "Secret Manager secret ID for Portainer admin password"
  value       = google_secret_manager_secret.portainer_admin_password.secret_id
}

output "grafana_admin_password_secret_id" {
  description = "Secret Manager secret ID for Grafana admin password"
  value       = google_secret_manager_secret.grafana_admin_password.secret_id
}

output "slack_webhook_url_secret_id" {
  description = "Secret Manager secret ID for Slack webhook URL"
  value       = google_secret_manager_secret.slack_webhook_url.secret_id
}
