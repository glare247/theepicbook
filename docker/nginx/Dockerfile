
# ─────────────────────────────────────────────────────────────────
# Nginx Reverse Proxy Dockerfile
#
# Official docs:
# https://hub.docker.com/_/nginx
# ─────────────────────────────────────────────────────────────────

FROM nginx:alpine

# Upgrade OS packages, remove default config, create static assets dir
RUN apk upgrade --no-cache && \
    rm /etc/nginx/nginx.conf && \
    mkdir -p /app/public/assets

# Copy our custom Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
  --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 \
  --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
