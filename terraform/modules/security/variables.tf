# ─────────────────────────────────────────────────────────────────
# SECURITY MODULE — VARIABLES
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

variable "rate_limit_threshold" {
  description = "Max requests per IP per interval before throttling"
  type        = number
  default     = 100
}

variable "rate_limit_interval_sec" {
  description = "Time window in seconds for rate limiting"
  type        = number
  default     = 60
}

variable "app_domain" {
  description = "Application domain for uptime monitoring"
  type        = string
  default     = "localhost"
}

variable "cpu_alert_threshold" {
  description = "CPU utilization threshold to trigger alert (0.0 to 1.0)"
  type        = number
  default     = 0.8
  # 0.8 = 80% CPU utilization
}

variable "memory_alert_threshold" {
  description = "Memory utilization threshold to trigger alert (0.0 to 100.0)"
  type        = number
  default     = 85.0
  # 85.0 = 85% memory utilization
}

variable "notification_channels" {
  description = "Cloud Monitoring notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to all security resources"
  type        = map(string)
  default     = {}
}