# ─────────────────────────────────────────────────────────────────
# CLOUD SQL MODULE — VARIABLES
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
  description = "GCP region for Cloud SQL instance"
  type        = string
  default     = "us-central1"
}

variable "vpc_self_link" {
  description = "VPC network self_link — from vpc module output. Required for Cloud SQL private IP."
  type        = string
}

variable "private_vpc_connection_id" {
  description = "Private Service Access connection ID — from vpc module output. Ensures PSA peering exists before Cloud SQL instance is created."
  type        = string
}

variable "db_tier" {
  description = "Cloud SQL machine tier. dev=db-f1-micro, staging=db-g1-small, prod=db-n1-standard-2"
  type        = string
  # Tier options:
  # db-f1-micro    — 1 shared vCPU, 614 MB  (dev only)
  # db-g1-small    — 1 shared vCPU, 1.7 GB  (staging)
  # db-n1-standard-2 — 2 vCPU, 7.5 GB      (prod)
}

variable "availability_type" {
  description = "ZONAL for single-zone (dev/staging) or REGIONAL for HA with automatic failover (prod)"
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL"
  }
}

variable "disk_size_gb" {
  description = "Initial disk size in GB — Cloud SQL autoresizes when needed"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb must be at least 10"
  }
}

variable "deletion_protection" {
  description = "Prevent accidental deletion. Set true for prod, false for dev/staging."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of daily backups to retain"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "backup_retention_days must be between 1 and 365"
  }
}

variable "labels" {
  description = "Labels to apply to Cloud SQL resources"
  type        = map(string)
  default     = {}
}
