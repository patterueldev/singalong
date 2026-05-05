# Singalong Node Service - Release Dockerfile
#
# Multi-stage build for production deployment
# Includes embedded React admin UI
#
# Stage 1: Build React Admin UI
FROM node:20-alpine AS admin-builder

WORKDIR /build/admin

# Copy admin package files
COPY apps/singalong-admin/package.json apps/singalong-admin/yarn.lock* ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy admin source code
COPY apps/singalong-admin/public ./public
COPY apps/singalong-admin/src ./src
COPY apps/singalong-admin/index.html ./
COPY apps/singalong-admin/vite.config.ts ./
COPY apps/singalong-admin/tsconfig.json ./
COPY apps/singalong-admin/tsconfig.app.json ./
COPY apps/singalong-admin/tsconfig.node.json ./
COPY apps/singalong-admin/eslint.config.js ./

# Build for production
RUN yarn build

# Stage 2: Python Builder
FROM python:3.11-slim AS python-builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    git \
    && pip install --no-cache-dir poetry \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY apps/singalong-node/pyproject.toml apps/singalong-node/poetry.lock* ./

# Install Python dependencies
RUN poetry config virtualenvs.create false && \
    poetry install --no-interaction --no-ansi --only main

# Copy application code
COPY apps/singalong-node/ .

# Stage 3: Runtime
FROM python:3.11-slim

WORKDIR /app

# Install minimal runtime dependencies (no dev tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy installed dependencies from python builder
COPY --from=python-builder /usr/local /usr/local

# Copy application code from python builder
COPY --from=python-builder /build .

# Copy built React admin UI from admin builder
COPY --from=admin-builder /build/admin/dist ./app/static/admin

# Create data and logs directories that need to exist for volumes
# Make them world-writable for bind-mounted directories
RUN mkdir -p /data/node && chmod 777 /data/node

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
# TODO: Switch to appuser when database permissions are fully resolved
# USER appuser

# Expose port
EXPOSE 5002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5002/health').read()" || exit 1

# Run production server (no reload, no debug)
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5002"]
