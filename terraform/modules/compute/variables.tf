# ─────────────────────────────────────────────────────────────────
# COMPUTE MODULE — VARIABLES
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

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCE machine type — controls CPU and memory"
  type        = string
  # dev     = "e2-medium"      2 vCPU / 4GB
  # staging = "e2-standard-2"  2 vCPU / 8GB
  # prod    = "n2-standard-4"  4 vCPU / 16GB
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 500
    error_message = "disk_size_gb must be between 10 and 500"
  }
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"

  validation {
    condition     = contains(["pd-ssd", "pd-standard", "pd-balanced"], var.disk_type)
    error_message = "disk_type must be pd-ssd, pd-standard or pd-balanced"
  }
}

variable "subnet_id" {
  description = "Private subnet ID — from vpc module output"
  type        = string
}

variable "vm_sa_email" {
  description = "VM service account email — from serviceaccounts module output"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the VM"
  type        = map(string)
  default     = {}
}