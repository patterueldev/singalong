# Singalong Node Service - Release Dockerfile
#
# Multi-stage build for production deployment
# Optimized for smaller image size and faster startup
#
# Stage 1: Builder
FROM python:3.11-slim as builder

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
COPY pyproject.toml poetry.lock* ./

# Install Python dependencies
RUN poetry config virtualenvs.create false && \
    poetry install --no-interaction --no-ansi --only main

# Copy application code
COPY . ./

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

# Install minimal runtime dependencies (no dev tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy installed dependencies from builder
COPY --from=builder /usr/local /usr/local

# Copy application code from builder
COPY --from=builder /build .

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
