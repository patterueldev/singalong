FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Copy project files
COPY pyproject.toml ./
COPY app.py ./
COPY run.sh ./

# Install dependencies
RUN poetry install --only main

# Make script executable
RUN chmod +x run.sh

# Run the bridge
CMD ["./run.sh"]
