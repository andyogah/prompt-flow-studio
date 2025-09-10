FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry==1.7.1

# Configure Poetry - disable virtual env creation
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_CREATE=false \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

# Copy dependency files first for better caching
COPY pyproject.toml poetry.lock* ./

# Ensure poetry.lock is valid before installing dependencies
RUN if [ ! -f poetry.lock ]; then \
        echo "Error: poetry.lock is missing. Please generate it with 'poetry lock'." && exit 1; \
    fi && \
    poetry check && \
    poetry install --only=main --no-root && \
    rm -rf $POETRY_CACHE_DIR

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy application code
COPY . .

# Change ownership
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# Run uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
