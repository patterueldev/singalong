FROM nginx:1.25-alpine

# Copy custom nginx configuration
COPY infrastructure/development/nginx.conf /etc/nginx/conf.d/default.conf

# Create nginx cache directory
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/api/health || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
