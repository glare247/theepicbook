# ─────────────────────────────────────────────────────────────────
# DEV ENVIRONMENT — OUTPUTS
#
# These print to your terminal after terraform apply
# Very useful — tells you exactly what was created
# Docs: https://developer.hashicorp.com/terraform/language/values/outputs
# ─────────────────────────────────────────────────────────────────

# ── VM Outputs ────────────────────────────────────────────────────
output "vm_name" {
  description = "VM name — use this to SSH via IAP"
  value       = module.compute.vm_name
}

output "vm_internal_ip" {
  description = "VM internal IP address"
  value       = module.compute.vm_internal_ip
}

output "vm_zone" {
  description = "VM zone"
  value       = module.compute.vm_zone
}

# ── Load Balancer Outputs ─────────────────────────────────────────
output "lb_ip_address" {
  description = "Load balancer public IP — point DNS here"
  value       = module.loadbalancer.lb_ip_address
}

# ── Artifact Registry Outputs ─────────────────────────────────────
output "repository_url" {
  description = "Artifact Registry URL — used in GitHub Actions"
  value       = module.artifactregistry.repository_url
}

output "backend_image_url" {
  description = "Backend image URL — used in docker-compose"
  value       = module.artifactregistry.backend_image_url
}

output "frontend_image_url" {
  description = "Frontend image URL — used in docker-compose"
  value       = module.artifactregistry.frontend_image_url
}

# ── Storage Outputs ───────────────────────────────────────────────
output "bucket_name" {
  description = "GCS bucket name"
  value       = module.storage.bucket_name
}

# ── Service Account Outputs ───────────────────────────────────────
output "github_actions_sa_email" {
  description = "GitHub Actions SA — add to GitHub secrets"
  value       = module.serviceaccounts.github_actions_sa_email
}

output "workload_identity_provider" {
  description = "WIF provider — add to GitHub secrets"
  value       = module.serviceaccounts.workload_identity_provider
}

# ── Secret Manager Outputs ────────────────────────────────────────
output "database_url_secret_id" {
  description = "Secret ID for DATABASE_URL"
  value       = module.security.database_url_secret_id
}

# ── Cloud SQL Outputs ─────────────────────────────────────────────
output "cloudsql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloudsql.instance_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL private IP — only reachable from within the VPC"
  value       = module.cloudsql.private_ip
}

output "cloudsql_connection_name" {
  description = "Cloud SQL connection name — format: project:region:instance"
  value       = module.cloudsql.instance_connection_name
}

output "db_host_secret_id" {
  description = "Secret ID for DB_HOST — populated by cloudsql module"
  value       = module.cloudsql.db_host_secret_id
}

output "db_password_secret_id" {
  description = "Secret ID for DB_PASSWORD — populated by cloudsql module"
  value       = module.cloudsql.db_password_secret_id
}

# ── SSH Command ───────────────────────────────────────────────────
output "ssh_command" {
  description = "Exact command to SSH into VM via IAP"
  value       = "gcloud compute ssh ${module.compute.vm_name} --zone=${module.compute.vm_zone} --tunnel-through-iap --project=${var.project_id}"
}