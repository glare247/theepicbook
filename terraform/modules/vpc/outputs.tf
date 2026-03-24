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

output "vpc_self_link" {
  description = "VPC self_link — required by Cloud SQL for private IP configuration"
  value       = google_compute_network.vpc.self_link
}

output "private_vpc_connection_id" {
  description = "Private Service Access connection ID — passed to cloudsql module to ensure PSA is ready before Cloud SQL instance creation"
  value       = google_service_networking_connection.private_vpc_connection.id
}