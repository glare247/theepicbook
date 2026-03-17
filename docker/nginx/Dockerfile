
# ─────────────────────────────────────────────────────────────────
# Nginx Reverse Proxy Dockerfile
#
# Official docs:
# https://hub.docker.com/_/nginx
# ─────────────────────────────────────────────────────────────────

FROM nginx:alpine

# Remove default Nginx config
RUN rm /etc/nginx/nginx.conf

# Copy our custom Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Create directory for static files
RUN mkdir -p /app/public/assets

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
  --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 \
  --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
