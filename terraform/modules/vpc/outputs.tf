# ─────────────────────────────────────────────────────────────────
# VPC MODULE — OUTPUTS
#
# These values are passed to other modules:
# vpc_id    → database module, security module
# vpc_name  → firewall rules, load balancer
# subnet_id → compute module
# ─────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC network ID — used by compute and security modules"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC network name — used by load balancer"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Private subnet ID — used by compute module"
  value       = google_compute_subnetwork.private.id
}

output "subnet_cidr" {
  description = "Subnet CIDR range — used by security module"
  value       = google_compute_subnetwork.private.ip_cidr_range
}