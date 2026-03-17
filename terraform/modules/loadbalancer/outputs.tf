# ─────────────────────────────────────────────────────────────────
# LOAD BALANCER MODULE — OUTPUTS
#
# These values are used by:
# lb_ip_address → point your DNS A record here
# backend_service_id → referenced in monitoring
# ─────────────────────────────────────────────────────────────────

output "lb_ip_address" {
  description = "Load balancer public IP — point your DNS A record to this"
  value       = google_compute_global_address.lb_ip.address
}

output "lb_ip_name" {
  description = "Load balancer IP resource name"
  value       = google_compute_global_address.lb_ip.name
}

output "backend_service_id" {
  description = "Backend service ID — used by monitoring"
  value       = google_compute_backend_service.app_backend.id
}

output "url_map_id" {
  description = "URL map ID"
  value       = google_compute_url_map.url_map.id
}