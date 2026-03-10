# Quick Start Guide

## 1. Installation

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Or install package
pip install -e .
```

## 2. Prepare Training Data

Place benign access logs in `data/benign_logs/`:

```bash
mkdir -p data/benign_logs
# Copy your Apache/Nginx access logs here
cp /var/log/nginx/access.log* data/benign_logs/
```

## 3. Train the Model

```bash
python -m model.train \
    --log-dir data/benign_logs \
    --output-dir models/waf_transformer \
    --epochs 10 \
    --batch-size 64
```

This will take 1-3 hours depending on data size and hardware.

## 4. Start the API

```bash
python -m api.waf_api --host 0.0.0.0 --port 8000
```

## 5. Test the API

```bash
curl -X POST http://localhost:8000/scan \
  -H "Content-Type: application/json" \
  -d '{
    "method": "GET",
    "path": "/api/users/123",
    "query_string": "format=json",
    "headers": {"User-Agent": "Mozilla/5.0"},
    "body": ""
  }'
```

## 6. Deploy with Docker

```bash
cd docker
docker-compose up -d
```

## 7. Configure Web Server

See `integration/nginx.conf` or `integration/apache.conf` for examples.

## Troubleshooting

**CUDA out of memory**: Reduce batch size or use CPU
**Model not loading**: Check model path in config
**High false positives**: Increase threshold (e.g., 0.85)

For full documentation, see README.md
