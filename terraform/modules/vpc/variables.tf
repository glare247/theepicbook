# ─────────────────────────────────────────────────────────────────
# VPC MODULE — VARIABLES
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
  description = "GCP region to deploy into"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR e.g. 10.0.1.0/24"
  }
}