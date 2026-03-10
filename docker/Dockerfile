# Transformer WAF Docker Image
# Production-ready container for anomaly detection service

FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/models /app/logs /app/data /app/checkpoints

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV WAF_MODEL_PATH=/app/models/waf_transformer
ENV WAF_LOG_LEVEL=INFO
ENV WAF_DEVICE=cpu
ENV WAF_API_HOST=0.0.0.0
ENV WAF_API_PORT=8000

# Expose API port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run API service
CMD ["python", "-m", "api.waf_api", "--host", "0.0.0.0", "--port", "8000"]
