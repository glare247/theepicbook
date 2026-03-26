
# ─────────────────────────────────────────────────────────────────
# SERVICE ACCOUNTS MODULE
#
# Official docs:
# https://cloud.google.com/iam/docs/service-accounts
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id
#
# Uses random_id to permanently solve WIF pool soft-delete conflict
# GCP soft-deletes WIF pools for 30 days after terraform destroy
# random_id generates a unique suffix every time — no conflicts ever
# ─────────────────────────────────────────────────────────────────

# ── Random suffix — solves WIF pool soft-delete problem ──────────
# Generates unique hex e.g. "a3f2b1c4"
# Stored in state file — stays same across applies
# Only generates new value after terraform destroy
resource "random_id" "pool_suffix" {
  byte_length = 4
}

# ── 1. GitHub Actions Service Account ────────────────────────────
resource "google_service_account" "github_actions_sa" {
  account_id   = "${var.env}-github-actions-sa"
  display_name = "GitHub Actions SA - ${var.env}"
  description  = "Used by GitHub Actions CI to push images to Artifact Registry"
  project      = var.project_id
}

# ── 2. VM Service Account ─────────────────────────────────────────
resource "google_service_account" "vm_sa" {
  account_id   = "${var.env}-vm-sa"
  display_name = "VM Service Account - ${var.env}"
  description  = "Used by GCE VM to pull images and access GCP APIs"
  project      = var.project_id
}

# ── 3. IAM — VM SA can write logs ────────────────────────────────
resource "google_project_iam_member" "vm_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# ── 4. IAM — VM SA can write metrics ─────────────────────────────
resource "google_project_iam_member" "vm_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# ── 5. IAM — VM SA can read secrets ──────────────────────────────
resource "google_project_iam_member" "vm_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# ── 6. IAM — VM SA can pull from Artifact Registry ───────────────
resource "google_project_iam_member" "vm_sa_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# ── 7. IAM — VM SA can connect to Cloud SQL ──────────────────────
resource "google_project_iam_member" "vm_sa_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# ── 8. IAM — GitHub Actions SA can push to Artifact Registry ─────
resource "google_project_iam_member" "github_actions_sa_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# ── 9. IAM — GitHub Actions SA can SSH into VM via Cloud IAP ─────
# Required for CD pipeline: gcloud compute ssh --tunnel-through-iap
# Without this, IAP rejects the tunnel connection with 403
# Docs: https://cloud.google.com/iap/docs/using-tcp-forwarding
resource "google_project_iam_member" "github_actions_sa_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# ── 10. IAM — GitHub Actions SA can use OS Login on the VM ───────
# OS Login links GCP IAM identity to the Linux user on the VM
# Required alongside IAP tunnel role for SSH to actually work
# Docs: https://cloud.google.com/compute/docs/oslogin
resource "google_project_iam_member" "github_actions_sa_os_login" {
  project = var.project_id
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# ── 8. Workload Identity Pool ─────────────────────────────────────
# random_id suffix makes name unique every time
# Example: dev-github-pool-a3f2b1c4
# After destroy → new suffix → dev-github-pool-9d1e4f2a
# Old soft-deleted name never reused → no conflict ever
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "${var.env}-github-pool-${random_id.pool_suffix.hex}"
  display_name              = "GitHub Actions Pool - ${var.env}"
  description               = "Workload Identity Pool for GitHub Actions"
  project                   = var.project_id
  disabled                  = false
}

# ── 9. Workload Identity Provider ────────────────────────────────
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.env}-github-provider-${random_id.pool_suffix.hex}"
  project                            = var.project_id
  display_name                       = "GitHub Provider - ${var.env}"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ── 10. Allow GitHub Actions from your repo to use the SA ────────
resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}
