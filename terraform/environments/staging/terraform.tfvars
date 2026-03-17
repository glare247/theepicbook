# ── Core ──────────────────────────────────────────────────────────
env        = "staging"
project_id = "expandox-project-2"
region     = "us-central1"
zone       = "us-central1-a"

# ── Network ───────────────────────────────────────────────────────
subnet_cidr = "10.0.2.0/24"

# ── Compute — medium for staging ──────────────────────────────────
machine_type = "e2-standard-2"
disk_size_gb = 30
disk_type    = "pd-ssd"

# ── Artifact Registry ─────────────────────────────────────────────
repository_id = "cloudopshub-staging"

# ── Service Accounts ──────────────────────────────────────────────
github_repo = "glare247/theepicbook"

# ── Security ──────────────────────────────────────────────────────
rate_limit_threshold    = 200
rate_limit_interval_sec = 60
app_domain              = "staging.cloudopshub.com"
cpu_alert_threshold     = 0.75
memory_alert_threshold  = 80.0

# ── Load Balancer ─────────────────────────────────────────────────
health_check_path = "/health"
ssl_domains       = []

# ── Storage ───────────────────────────────────────────────────────
force_destroy      = true
versioning_enabled = true
retention_versions = 3