# ─────────────────────────────────────────────────────────────────
# STORAGE MODULE — VARIABLES
# Docs: https://developer.hashicorp.com/terraform/language/values/variables
# ─────────────────────────────────────────────────────────────────

variable "env" {
  description = "Environment name — dev, staging or prod"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of: dev, staging, prod"
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCS bucket location"
  type        = string
  default     = "us-central1"
}

variable "force_destroy" {
  description = "Allow bucket deletion even if it contains files — false in prod"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning for file recovery"
  type        = bool
  default     = true
}

variable "retention_versions" {
  description = "Number of older versions to keep before auto-deleting"
  type        = number
  default     = 3
}

variable "vm_sa_email" {
  description = "VM service account email — from serviceaccounts module output"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the GCS bucket"
  type        = map(string)
  default     = {}
}