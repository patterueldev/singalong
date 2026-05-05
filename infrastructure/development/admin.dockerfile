# Singalong Admin Dashboard - Development Dockerfile
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package.json yarn.lock* package-lock.json* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then \
    yarn install --frozen-lockfile; \
    else \
    npm ci; \
    fi

# Don't copy app code here - let volume mount handle it
# Volume mount will override this path during development

# Expose port
EXPOSE 3001

# Run with hot-reload
# Vite watches for changes on the mounted volume
CMD ["yarn", "dev", "--host", "0.0.0.0", "--strictPort", "false"]

