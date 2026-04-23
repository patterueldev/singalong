# Singalong Controller - Development Dockerfile
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy dependency files
COPY apps/singalong-controller/package.json apps/singalong-controller/yarn.lock* apps/singalong-controller/package-lock.json* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then \
    yarn install --frozen-lockfile; \
    else \
    npm ci; \
    fi

# Copy application code
COPY apps/singalong-controller ./

# Expose port
EXPOSE 3002

# Run with hot-reload
CMD ["yarn", "dev", "--host", "0.0.0.0"]
