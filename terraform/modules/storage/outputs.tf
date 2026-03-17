# ─────────────────────────────────────────────────────────────────
# STORAGE MODULE — OUTPUTS
#
# These values are used by:
# bucket_name → application config for static file uploads
# bucket_url  → docker-compose environment variables
# ─────────────────────────────────────────────────────────────────

output "bucket_name" {
  description = "GCS bucket name — used by app to upload static files"
  value       = google_storage_bucket.assets.name
}

output "bucket_url" {
  description = "GCS bucket URL — used in application environment variables"
  value       = google_storage_bucket.assets.url
}

output "bucket_self_link" {
  description = "GCS bucket self link"
  value       = google_storage_bucket.assets.self_link
}