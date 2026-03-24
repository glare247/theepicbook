# ─────────────────────────────────────────────────────────────────
# DEV ENVIRONMENT — VALUES
#


# ── Core ──────────────────────────────────────────────────────────
env        = "dev"
project_id = "expandox-project-2"
region     = "us-central1"
zone       = "us-central1-a"

# ── Network ───────────────────────────────────────────────────────
subnet_cidr = "10.0.1.0/24"

# ── Compute — small size for dev ──────────────────────────────────
machine_type = "e2-medium"
disk_size_gb = 20
disk_type    = "pd-ssd"

# ── Artifact Registry ─────────────────────────────────────────────
repository_id = "cloudopshub"

# ── Service Accounts ──────────────────────────────────────────────

github_repo = "glare247/theepicbook"

# ── Security ──────────────────────────────────────────────────────
rate_limit_threshold    = 100
rate_limit_interval_sec = 60
app_domain              = "localhost"
cpu_alert_threshold     = 0.8
memory_alert_threshold  = 85.0

# ── Load Balancer ─────────────────────────────────────────────────
health_check_path = "/health"
ssl_domains       = []            

# ── Cloud SQL ─────────────────────────────────────────────────────
db_tier                  = "db-f1-micro"   # smallest/cheapest — 1 shared vCPU, 614 MB
db_availability_type     = "ZONAL"         # single-zone is fine for dev
db_disk_size_gb          = 20
db_deletion_protection   = false           # allow destroy in dev
db_backup_retention_days = 3              # minimal backups for dev

# ── Storage ───────────────────────────────────────────────────────
force_destroy      = true        
versioning_enabled = true
retention_versions = 3