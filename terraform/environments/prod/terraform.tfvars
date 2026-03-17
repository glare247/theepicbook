# ── Core ──────────────────────────────────────────────────────────
env        = "prod"
project_id = "expandox-project-2"
region     = "us-central1"
zone       = "us-central1-a"

# ── Network ───────────────────────────────────────────────────────
subnet_cidr = "10.0.3.0/24"

# ── Compute — largest for prod ────────────────────────────────────
machine_type = "n2-standard-4"
disk_size_gb = 50
disk_type    = "pd-ssd"

# ── Artifact Registry ─────────────────────────────────────────────
repository_id = "cloudopshub-prod"

# ── Service Accounts ──────────────────────────────────────────────
github_repo = "glare247/theepicbook"

# ── Security — tighter limits for prod ───────────────────────────
rate_limit_threshold    = 500
rate_limit_interval_sec = 60
app_domain              = "cloudopshub.com"
cpu_alert_threshold     = 0.7
memory_alert_threshold  = 75.0

# ── Load Balancer ─────────────────────────────────────────────────
health_check_path = "/health"
ssl_domains       = ["cloudopshub.com"]

# ── Storage ───────────────────────────────────────────────────────
force_destroy      = false        
versioning_enabled = true
retention_versions = 5