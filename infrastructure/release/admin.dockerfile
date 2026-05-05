# Singalong Admin UI - Release Dockerfile
#
# Multi-stage build for production deployment
# Optimized for smaller image size using Node.js + Vite
#
# Stage 1: Builder
FROM node:20-alpine AS builder

WORKDIR /build

# Install dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production=false

# Copy application code
COPY . ./

# Build React app with Vite
RUN yarn build

# Stage 2: Runtime (Nginx to serve static files)
FROM nginx:1.25-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built app from builder
COPY --from=builder /build/dist /usr/share/nginx/html

# Set permissions for nginx user (already exists in nginx image)
RUN chown -R nginx:nginx /usr/share/nginx/html

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://localhost:3001/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
