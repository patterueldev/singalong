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

# Don't copy app code here - let volume mount handle it
# Volume mount will override this path during development

# Expose port
EXPOSE 3002

# Run with hot-reload
# Vite watches for changes on the mounted volume
CMD ["yarn", "dev", "--host", "0.0.0.0", "--strictPort", "false"]

