# ─────────────────────────────────────────────────────────────────
# DEV ENVIRONMENT — VARIABLES
#
# All values live in terraform.tfvars — never hardcoded here
# Docs: https://developer.hashicorp.com/terraform/language/values/variables
# ─────────────────────────────────────────────────────────────────

# ── CORE ──────────────────────────────────────────────────────────
variable "env" {
  description = "Environment name"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
}

# ── NETWORK ───────────────────────────────────────────────────────
variable "subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}

# ── COMPUTE ───────────────────────────────────────────────────────
variable "machine_type" {
  description = "GCE VM machine type"
  type        = string
}

variable "disk_size_gb" {
  description = "VM boot disk size in GB"
  type        = number
}

variable "disk_type" {
  description = "VM boot disk type"
  type        = string
}

# ── ARTIFACT REGISTRY ─────────────────────────────────────────────
variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
}

# ── SERVICE ACCOUNTS ──────────────────────────────────────────────
variable "github_repo" {
  description = "GitHub repo in format owner/repo-name"
  type        = string
}

# ── SECURITY ──────────────────────────────────────────────────────
variable "rate_limit_threshold" {
  description = "Max requests per IP per interval"
  type        = number
}

variable "rate_limit_interval_sec" {
  description = "Rate limit time window in seconds"
  type        = number
}

variable "app_domain" {
  description = "App domain for uptime checks"
  type        = string
}

variable "cpu_alert_threshold" {
  description = "CPU alert threshold 0.0 to 1.0"
  type        = number
}

variable "memory_alert_threshold" {
  description = "Memory alert threshold 0.0 to 100.0"
  type        = number
}

# ── LOAD BALANCER ─────────────────────────────────────────────────
variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
}

variable "ssl_domains" {
  description = "Domains for SSL certificate"
  type        = list(string)
}

# ── STORAGE ───────────────────────────────────────────────────────
variable "force_destroy" {
  description = "Allow non-empty bucket deletion"
  type        = bool
}

variable "versioning_enabled" {
  description = "Enable GCS object versioning"
  type        = bool
}

variable "retention_versions" {
  description = "Versions to keep before deletion"
  type        = number
}
