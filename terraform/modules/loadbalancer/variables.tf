# ─────────────────────────────────────────────────────────────────
# LOAD BALANCER MODULE — VARIABLES
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
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "vm_self_link" {
  description = "VM self link — from compute module output"
  type        = string
}

variable "vm_zone" {
  description = "VM zone — from compute module output"
  type        = string
}

variable "waf_policy_id" {
  description = "Cloud Armor WAF policy ID — from security module output"
  type        = string
}

variable "health_check_path" {
  description = "HTTP path for load balancer health checks"
  type        = string
  default     = "/health"
}

variable "ssl_domains" {
  description = "List of domains for managed SSL certificate — empty list skips SSL"
  type        = list(string)
  default     = []
  # dev     = []                             no SSL
  # staging = ["staging.cloudopshub.com"]   with SSL
  # prod    = ["cloudopshub.com"]           with SSL
}

variable "labels" {
  description = "Labels for load balancer resources"
  type        = map(string)
  default     = {}
}