# ─────────────────────────────────────────────────────────────────
# COMPUTE MODULE — OUTPUTS
#
# These values are passed to other modules:
# vm_name      → ArgoCD deploy script
# vm_internal_ip → load balancer backend
# vm_self_link → load balancer instance group
# vm_zone      → load balancer instance group
# ─────────────────────────────────────────────────────────────────

output "vm_name" {
  description = "VM name — used by ArgoCD deploy script and IAP SSH"
  value       = google_compute_instance.app_vm.name
}

output "vm_internal_ip" {
  description = "Internal IP — used by load balancer backend service"
  value       = google_compute_instance.app_vm.network_interface[0].network_ip
}

output "vm_self_link" {
  description = "VM self link — used by load balancer instance group"
  value       = google_compute_instance.app_vm.self_link
}

output "vm_zone" {
  description = "VM zone — used by load balancer instance group"
  value       = google_compute_instance.app_vm.zone
}