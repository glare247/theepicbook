locals {

  # Standard labels applied to EVERY resource in prod
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