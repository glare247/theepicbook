# ─────────────────────────────────────────────────────────────────
# SERVICE ACCOUNTS MODULE — VARIABLES
#
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

variable "github_repo" {
  description = "GitHub repository in format owner/repo-name e.g. kabir/theepicbook"
  type        = string
}
