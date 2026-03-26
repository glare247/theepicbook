
# ─────────────────────────────────────────────────────────────────
# TheEpicBook — Node.js Application Dockerfile
#
# Official docs:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices
# https://hub.docker.com/_/node
#
# Multi-stage build:
# Stage 1 — builder: installs all dependencies
# Stage 2 — production: copies only what is needed
# Result: smaller and more secure final image
#
# App facts from package.json:
# - Entry point: server.js
# - Port: process.env.PORT || 8080
# - Framework: Express + Handlebars
# - Database: Sequelize + mysql2
# ─────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ──────────────────────────────────────────────
FROM node:18-alpine AS builder

# Upgrade OS packages to patch CVEs in base image (e.g. CVE-2025-15467 OpenSSL)
RUN apk upgrade --no-cache

WORKDIR /app

# Copy package files first
# Docker caches this layer separately
# npm install only reruns when package.json changes
COPY package*.json ./

# Install all dependencies
RUN npm ci

# Copy all application source code
COPY . .

# ── Stage 2: Production ───────────────────────────────────────────
FROM node:18-alpine

# Upgrade OS packages to patch CVEs in base image (e.g. CVE-2025-15467 OpenSSL)
RUN apk upgrade --no-cache

# Create non-root user — containers must never run as root
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Copy only the files the app needs to run
COPY --from=builder /app/config  ./config
COPY --from=builder /app/models  ./models
COPY --from=builder /app/routes  ./routes
COPY --from=builder /app/views   ./views
COPY --from=builder /app/public  ./public
COPY --from=builder /app/server.js ./server.js

# Switch to non-root user
USER appuser

# Expose app port
EXPOSE 8080

# Health check — used by docker-compose depends_on
HEALTHCHECK --interval=30s --timeout=10s \
  --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 \
  --spider http://localhost:8080/ || exit 1

# Start the app
CMD ["node", "server.js"]
