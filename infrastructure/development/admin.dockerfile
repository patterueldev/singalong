# Singalong Admin Dashboard - Development Dockerfile
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy dependency files
COPY apps/singalong-admin/package.json apps/singalong-admin/yarn.lock* apps/singalong-admin/package-lock.json* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then \
    yarn install --frozen-lockfile; \
    else \
    npm ci; \
    fi

# Copy application code
COPY apps/singalong-admin ./

# Expose port
EXPOSE 3001

# Run with hot-reload
CMD ["yarn", "dev", "--host", "0.0.0.0"]
