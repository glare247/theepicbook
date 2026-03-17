
output "github_actions_sa_email" {
  description = "GitHub Actions SA email — add to GitHub secrets"
  value       = google_service_account.github_actions_sa.email
}

output "vm_sa_email" {
  description = "VM SA email — attached to GCE VM"
  value       = google_service_account.vm_sa.email
}

output "workload_identity_provider" {
  description = "Full WIF provider name — add to GitHub Actions secret"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_actions_sa_name" {
  description = "Full SA resource name"
  value       = google_service_account.github_actions_sa.name
}
