# Singalong Node Service - Development Dockerfile
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies and Poetry
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    && pip install --no-cache-dir poetry \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY pyproject.toml poetry.lock* ./

# Install Python dependencies
RUN poetry config virtualenvs.create false && \
    poetry install --no-interaction --no-ansi

# Copy application code
COPY . ./

# Expose port
EXPOSE 5002

# Run with hot-reload
CMD ["poetry", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5002", "--reload"]
