# Production Deployment Guide

## Pre-Deployment Checklist

- [ ] Collected 10,000+ benign access logs for training
- [ ] Validated logs are clean (no attacks)
- [ ] Installed Python 3.10+
- [ ] (Optional) GPU with CUDA for faster training/inference
- [ ] Web server (Nginx/Apache) configured
- [ ] Network access between web server and WAF service

## Step 1: Environment Setup

### System Requirements

- **CPU**: 4+ cores
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 10GB for models and logs
- **GPU** (optional): NVIDIA GPU with 4GB+ VRAM
- **OS**: Linux (Ubuntu 20.04+) or Docker

### Installation

```bash
# Clone or copy project
cd transformer-waf

# Create virtual environment
python3.10 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Verify installation
python -c "import torch; import transformers; print('OK')"
```

## Step 2: Data Preparation

### Collect Benign Logs

```bash
# Create data directory
mkdir -p data/benign_logs

# Copy access logs (ensure they're benign!)
cp /var/log/nginx/access.log.* data/benign_logs/
# OR
cp /var/log/apache2/access.log.* data/benign_logs/

# Validate format
head -n 5 data/benign_logs/access.log.1
```

### Verify Log Quality

- Ensure no SQL injection attempts
- Ensure no path traversal attempts
- Ensure no suspicious user agents (scanners, bots)
- Filter by date range if needed

## Step 3: Model Training

### Initial Training

```bash
# Train model (adjust parameters based on data size)
python -m model.train \
    --log-dir data/benign_logs \
    --output-dir models/waf_transformer \
    --model-name distilbert-base-uncased \
    --epochs 10 \
    --batch-size 64 \
    --lr 2e-5 \
    --val-split 0.1 \
    --device cuda  # or cpu
```

**Expected Time**: 1-4 hours depending on data size and hardware

**Output**:
- Model checkpoint: `models/waf_transformer/model.pt`
- Encoder: `models/waf_transformer/encoder/`
- Tokenizer: `models/waf_transformer/tokenizer_config.json`

### Validate Training

```bash
# Check model files exist
ls -lh models/waf_transformer/
```

## Step 4: API Deployment

### Option A: Standalone Service

```bash
# Set environment variables
export WAF_MODEL_PATH=./models/waf_transformer
export WAF_ANOMALY_THRESHOLD=0.75
export WAF_DEVICE=cuda  # or cpu
export WAF_LOG_LEVEL=INFO
export WAF_ALERT_LOG_FILE=./logs/alerts.jsonl

# Start API
python -m api.waf_api --host 0.0.0.0 --port 8000 --workers 4
```

### Option B: Systemd Service

Create `/etc/systemd/system/transformer-waf.service`:

```ini
[Unit]
Description=Transformer WAF API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/transformer-waf
Environment="WAF_MODEL_PATH=/opt/transformer-waf/models/waf_transformer"
Environment="WAF_ANOMALY_THRESHOLD=0.75"
Environment="WAF_DEVICE=cuda"
ExecStart=/opt/transformer-waf/venv/bin/python -m api.waf_api --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable transformer-waf
sudo systemctl start transformer-waf
sudo systemctl status transformer-waf
```

### Option C: Docker Deployment

```bash
# Build image
cd docker
docker-compose build

# Start service
docker-compose up -d

# Check logs
docker-compose logs -f waf

# Check health
curl http://localhost:8000/health
```

## Step 5: Web Server Integration

### Nginx Configuration

```bash
# Backup existing config
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# Copy WAF config
sudo cp integration/nginx.conf /etc/nginx/sites-available/waf

# Update server_name and backend_app in config
sudo nano /etc/nginx/sites-available/waf

# Enable site
sudo ln -s /etc/nginx/sites-available/waf /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

### Apache Configuration

```bash
# Enable modules
sudo a2enmod proxy proxy_http headers rewrite

# Copy config
sudo cp integration/apache.conf /etc/apache2/sites-available/waf.conf

# Update ServerName and backend
sudo nano /etc/apache2/sites-available/waf.conf

# Enable site
sudo a2ensite waf

# Test config
sudo apachectl configtest

# Reload
sudo systemctl reload apache2
```

## Step 6: Validation

### Test WAF API

```bash
# Health check
curl http://localhost:8000/health

# Test scan
curl -X POST http://localhost:8000/scan \
  -H "Content-Type: application/json" \
  -d '{
    "method": "GET",
    "path": "/api/users",
    "query_string": "id=123",
    "headers": {},
    "body": ""
  }'
```

### Test Integration

```bash
# Make request to web server
curl http://your-domain.com/api/users

# Check WAF logs
tail -f logs/alerts.jsonl

# Check stats
curl http://localhost:8000/stats
```

## Step 7: Monitoring Setup

### Log Rotation

Create `/etc/logrotate.d/transformer-waf`:

```
/opt/transformer-waf/logs/*.log
/opt/transformer-waf/logs/*.jsonl {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 www-data www-data
    sharedscripts
    postrotate
        systemctl reload transformer-waf > /dev/null 2>&1 || true
    endscript
}
```

### Metrics Collection

Monitor these metrics:
- Requests per second
- Average anomaly score
- Detection rate (anomalies / total)
- API latency (p50, p95, p99)
- Error rate

### Alerting

Set up alerts for:
- High anomaly rate (>10%)
- API downtime
- High latency (>500ms)
- Disk space for logs

## Step 8: Continuous Learning

### Schedule Fine-Tuning

```bash
# Collect validated benign traffic weekly
# Fine-tune model
python -m model.fine_tune \
    --model-path models/waf_transformer \
    --log-file data/new_benign/week_52.log \
    --epochs 3 \
    --lr 1e-5

# Restart API to load updated model
sudo systemctl restart transformer-waf
```

## Step 9: Threshold Tuning

### Initial Calibration

```bash
# Run on known benign traffic, collect scores
# Analyze distribution
python scripts/analyze_scores.py

# Adjust threshold to minimize false positives
# Typical range: 0.70 - 0.85
curl -X POST http://localhost:8000/threshold?threshold=0.80
```

### Monitor and Adjust

- Start conservative (0.85+)
- Review alerts for false positives
- Gradually lower threshold
- Target: <1% false positive rate

## Step 10: Backup and Recovery

### Backup

```bash
# Backup model
tar -czf waf_model_$(date +%Y%m%d).tar.gz models/

# Backup config
cp utils/config.py config_$(date +%Y%m%d).py.bak

# Upload to S3/storage
aws s3 cp waf_model_$(date +%Y%m%d).tar.gz s3://backups/
```

### Recovery

```bash
# Download backup
aws s3 cp s3://backups/waf_model_20260122.tar.gz .

# Extract
tar -xzf waf_model_20260122.tar.gz

# Restart service
sudo systemctl restart transformer-waf
```

## Troubleshooting

### API Won't Start

```bash
# Check logs
sudo journalctl -u transformer-waf -n 50

# Common issues:
# - Model path incorrect
# - CUDA not available (switch to CPU)
# - Port already in use
```

### High False Positive Rate

- Increase threshold (try 0.85)
- Retrain with more benign data
- Check for data quality issues

### Slow Inference

- Enable GPU if available
- Increase batch size
- Reduce max sequence length
- Use CPU with multiple workers

### Memory Issues

- Reduce batch size
- Use CPU instead of GPU
- Enable gradient checkpointing

## Production Checklist

- [ ] Model trained and validated
- [ ] API service running and healthy
- [ ] Web server integrated
- [ ] Traffic being mirrored
- [ ] Logs being written
- [ ] Monitoring configured
- [ ] Alerts set up
- [ ] Backup scheduled
- [ ] Threshold tuned
- [ ] Documentation updated

## Support

For issues, check:
1. README.md - General documentation
2. ARCHITECTURE.md - System design
3. QUICKSTART.md - Quick setup
4. Logs in `logs/` directory

## Security Hardening

- [ ] Enable API authentication (set WAF_API_KEY)
- [ ] Restrict WAF API to localhost/internal network
- [ ] Use HTTPS for all communications
- [ ] Encrypt model checkpoints at rest
- [ ] Implement rate limiting
- [ ] Regular security audits
- [ ] Keep dependencies updated
