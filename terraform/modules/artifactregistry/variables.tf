# ─────────────────────────────────────────────────────────────────
# ARTIFACT REGISTRY MODULE — VARIABLES
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
  description = "Region for the Artifact Registry repository"
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "Unique repository ID — becomes part of the image URL"
  type        = string
  # Example: "cloudopshub"
  # Full URL: us-central1-docker.pkg.dev/expandox-project-2/cloudopshub/image:tag
}

variable "github_actions_sa_email" {
  description = "GitHub Actions SA email — from serviceaccounts module output"
  type        = string
}

variable "vm_sa_email" {
  description = "VM SA email — from serviceaccounts module output"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the repository"
  type        = map(string)
  default     = {}
}