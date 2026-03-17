# ─────────────────────────────────────────────────────────────────
# DEV ENVIRONMENT — LOCALS
#
# Locals are computed values derived from variables
# They are used across all module calls in this environment
# Docs: https://developer.hashicorp.com/terraform/language/values/locals
# ─────────────────────────────────────────────────────────────────

locals {

  # Standard labels applied to EVERY resource in dev
  # Meets GCP best practice for resource organisation
  # Docs: https://cloud.google.com/resource-manager/docs/creating-managing-labels
  common_labels = {
    environment = var.env
    project     = "cloudopshub"
    app         = "theepicbook"
    managed-by  = "terraform"
    team        = "devops"
  }
}