
# ─────────────────────────────────────────────────────────────────
# MySQL 8.4 Dockerfile
#
# Official docs:
# https://hub.docker.com/_/mysql
#
# MySQL Docker entrypoint automatically runs any .sql files
# placed in /docker-entrypoint-initdb.d/ on first startup
# ─────────────────────────────────────────────────────────────────

FROM mysql:8.4

# Copy init SQL — runs automatically on first container start
# Creates database, tables and seeds data
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql

# Expose MySQL port
EXPOSE 3306

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
  --start-period=60s --retries=5 \
  CMD mysqladmin ping -h localhost \
  -u root -p$$MYSQL_ROOT_PASSWORD || exit 1
