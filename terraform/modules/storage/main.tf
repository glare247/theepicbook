
# ─────────────────────────────────────────────────────────────────
# STORAGE MODULE
# https://cloud.google.com/storage/docs/introduction
# ─────────────────────────────────────────────────────────────────

resource "google_storage_bucket" "assets" {
  name                        = "${var.project_id}-${var.env}-assets"
  location                    = var.region
  project                     = var.project_id
  force_destroy               = var.force_destroy
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.retention_versions
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "vm_sa_storage_access" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.vm_sa_email}"
}
