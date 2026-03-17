# ─────────────────────────────────────────────────────────────────
# ARTIFACT REGISTRY MODULE
#
# Official docs:
# https://cloud.google.com/artifact-registry/docs/overview
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
#
# This module creates:
# 1. Docker repository in GCP Artifact Registry
#    - Replaces AWS ECR in our architecture
#    - Stores theepicbook-frontend and theepicbook-backend images
#    - Images tagged with Git commit SHA
#
# 2. IAM — GitHub Actions SA can PUSH images
# 3. IAM — VM SA can PULL images
#
# Image URL format after creation:
# us-central1-docker.pkg.dev/expandox-project-2/cloudopshub/theepicbook-backend:SHA
# us-central1-docker.pkg.dev/expandox-project-2/cloudopshub/theepicbook-frontend:SHA
# ─────────────────────────────────────────────────────────────────

# ── 1. Docker Repository ─────────────────────────────────────────
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = var.repository_id
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id
  description   = "CloudOpsHub ${var.env} Docker image repository"

  labels = var.labels
}

# ── 2. IAM — GitHub Actions SA can PUSH images ───────────────────
# GitHub Actions CI pipeline pushes built images here
# Docs: https://cloud.google.com/artifact-registry/docs/access-control
resource "google_artifact_registry_repository_iam_member" "github_actions_push" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.github_actions_sa_email}"
}

# ── 3. IAM — VM SA can PULL images ───────────────────────────────
# GCE VM pulls images when ArgoCD triggers deployment
# No static keys needed — VM authenticates via its service account
# Docs: https://cloud.google.com/artifact-registry/docs/docker/authentication
resource "google_artifact_registry_repository_iam_member" "vm_pull" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.vm_sa_email}"
}