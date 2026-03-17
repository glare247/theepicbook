# ─────────────────────────────────────────────────────────────────
# DEV ENVIRONMENT
#
# This file calls all 7 modules and wires them together
# Zero hardcoded values — everything from variables + locals
#
# Official docs:
# https://developer.hashicorp.com/terraform/language/modules
# https://developer.hashicorp.com/terraform/language/backend/gcs
# ─────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket = "cloudopshub-terraform-state"
    prefix = "terraform/dev"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}

# ── MODULE 1: SERVICE ACCOUNTS ────────────────────────────────────
# Must run first — other modules need its outputs
# Docs: https://cloud.google.com/iam/docs/service-accounts
module "serviceaccounts" {
  source      = "../../modules/serviceaccounts"
  env         = var.env
  project_id  = var.project_id
  github_repo = var.github_repo
}

# ── MODULE 2: VPC ─────────────────────────────────────────────────
# Creates the network everything runs on
# Docs: https://cloud.google.com/vpc/docs/overview
module "vpc" {
  source      = "../../modules/vpc"
  env         = var.env
  project_id  = var.project_id
  region      = var.region
  subnet_cidr = var.subnet_cidr
  
}

# ── MODULE 3: COMPUTE ─────────────────────────────────────────────
# Creates the GCE VM
# Uses subnet_id from vpc + vm_sa_email from serviceaccounts
# Docs: https://cloud.google.com/compute/docs/instances
module "compute" {
  source       = "../../modules/compute"
  env          = var.env
  project_id   = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb
  disk_type    = var.disk_type
  labels       = local.common_labels

  # ↓ Output from vpc module
  subnet_id = module.vpc.subnet_id

  # ↓ Output from serviceaccounts module
  vm_sa_email = module.serviceaccounts.vm_sa_email
}

# ── MODULE 4: ARTIFACT REGISTRY ───────────────────────────────────
# Creates Docker image repository
# Uses SA emails from serviceaccounts module
# Docs: https://cloud.google.com/artifact-registry/docs
module "artifactregistry" {
  source        = "../../modules/artifactregistry"
  env           = var.env
  project_id    = var.project_id
  region        = var.region
  repository_id = var.repository_id
  labels        = local.common_labels

  # ↓ Both outputs from serviceaccounts module
  github_actions_sa_email = module.serviceaccounts.github_actions_sa_email
  vm_sa_email             = module.serviceaccounts.vm_sa_email
}

# ── MODULE 5: STORAGE ─────────────────────────────────────────────
# Creates GCS bucket for static assets
# Uses vm_sa_email from serviceaccounts module
# Docs: https://cloud.google.com/storage/docs
module "storage" {
  source             = "../../modules/storage"
  env                = var.env
  project_id         = var.project_id
  region             = var.region
  force_destroy      = var.force_destroy
  versioning_enabled = var.versioning_enabled
  retention_versions = var.retention_versions
  labels             = local.common_labels

  # ↓ Output from serviceaccounts module
  vm_sa_email = module.serviceaccounts.vm_sa_email
}

# ── MODULE 6: SECURITY ────────────────────────────────────────────
# Creates Cloud Armor WAF + Secret Manager + Monitoring
# Runs independently — no module dependencies
# Docs: https://cloud.google.com/armor/docs
module "security" {
  source                  = "../../modules/security"
  env                     = var.env
  project_id              = var.project_id
  rate_limit_threshold    = var.rate_limit_threshold
  rate_limit_interval_sec = var.rate_limit_interval_sec
  app_domain              = var.app_domain
  cpu_alert_threshold     = var.cpu_alert_threshold
  memory_alert_threshold  = var.memory_alert_threshold
  labels                  = local.common_labels
}

# ── MODULE 7: LOAD BALANCER ───────────────────────────────────────
# Creates Cloud LB + SSL + WAF attachment
# Uses vm_self_link + vm_zone from compute
# Uses waf_policy_id from security
# Docs: https://cloud.google.com/load-balancing/docs
module "loadbalancer" {
  source            = "../../modules/loadbalancer"
  env               = var.env
  project_id        = var.project_id
  region            = var.region
  health_check_path = var.health_check_path
  ssl_domains       = var.ssl_domains
  labels            = local.common_labels

  # ↓ Both outputs from compute module
  vm_self_link = module.compute.vm_self_link
  vm_zone      = module.compute.vm_zone

  # ↓ Output from security module
  waf_policy_id = module.security.waf_policy_id
}