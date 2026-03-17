# ─────────────────────────────────────────────────────────────────
# ARTIFACT REGISTRY MODULE — OUTPUTS
#
# These values are used by:
# repository_url       → GitHub Actions workflow
# backend_image_url    → docker-compose.yml in gitops/
# frontend_image_url   → docker-compose.yml in gitops/
# ─────────────────────────────────────────────────────────────────

output "repository_id" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.docker_repo.repository_id
}

output "repository_url" {
  description = "Base repository URL — used in GitHub Actions to push images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "backend_image_url" {
  description = "Full backend image URL — append :tag when using in docker-compose"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/theepicbook-backend"
}

output "frontend_image_url" {
  description = "Full frontend image URL — append :tag when using in docker-compose"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/theepicbook-frontend"
}