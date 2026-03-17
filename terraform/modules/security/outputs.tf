# ─────────────────────────────────────────────────────────────────
# SECURITY MODULE — OUTPUTS
#
# These values are passed to other modules:
# waf_policy_id   → loadbalancer module (attached to backend service)
# waf_policy_name → loadbalancer module
# secret IDs      → application config + GitHub Actions secrets
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
  description = "Secret Manager secret ID for DATABASE_URL"
  value       = google_secret_manager_secret.database_url.secret_id
}

output "argocd_auth_token_secret_id" {
  description = "Secret Manager secret ID for ARGOCD_AUTH_TOKEN"
  value       = google_secret_manager_secret.argocd_auth_token.secret_id
}

output "grafana_admin_password_secret_id" {
  description = "Secret Manager secret ID for GRAFANA_ADMIN_PASSWORD"
  value       = google_secret_manager_secret.grafana_admin_password.secret_id
}

output "snyk_token_secret_id" {
  description = "Secret Manager secret ID for SNYK_TOKEN"
  value       = google_secret_manager_secret.snyk_token.secret_id
}