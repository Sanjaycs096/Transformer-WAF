# WAF Operations Guide

Quick reference for common operations and maintenance tasks.

## Daily Operations

### 1. Start the WAF API
```powershell
# Set environment variables
$env:WAF_DEVICE="cpu"  # or "cuda" if GPU available
$env:WAF_MODEL_PATH="models/waf_transformer"

# Start server (production)
py -m api.waf_api --host 0.0.0.0 --port 8000

# Start server (development/testing)
py -m api.waf_api --host 127.0.0.1 --port 8000
```

### 2. Check System Health
```powershell
# Quick health check
Invoke-RestMethod -Uri "http://127.0.0.1:8000/health"

# Get performance statistics
Invoke-RestMethod -Uri "http://127.0.0.1:8000/stats"
```

### 3. Scan a Request
```powershell
# Single request scan
$request = @{
    method = "GET"
    path = "/api/users"
    query_string = "page=1"
    headers = @{
        "User-Agent" = "Mozilla/5.0"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:8000/scan" `
    -Method POST `
    -Body $request `
    -ContentType "application/json"
```

### 4. Process Logs in Batch
```powershell
# Process Apache/Nginx logs
py -m ingestion.batch_ingest `
    --input-dir /var/log/apache2 `
    --output results.jsonl `
    --api-url http://127.0.0.1:8000 `
    --format jsonl
```

## Maintenance Tasks

### Update Anomaly Threshold
```powershell
# Adjust threshold based on your needs
# Lower = more sensitive (more alerts)
# Higher = less sensitive (fewer alerts)
$body = @{ threshold = 0.80 } | ConvertTo-Json
Invoke-RestMethod -Uri "http://127.0.0.1:8000/threshold" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"
```

### Retrain Model with New Data
```powershell
# 1. Collect new benign traffic
py scripts/generate_sample_logs.py `
    --output data/new_benign_logs `
    --count 10000

# 2. Train new model
py -m model.train `
    --log-dir data/new_benign_logs `
    --output-dir models/waf_v2 `
    --epochs 10 `
    --batch-size 32 `
    --max-samples 10000 `
    --device cuda  # Use GPU if available

# 3. Update environment variable
$env:WAF_MODEL_PATH="models/waf_v2"

# 4. Restart API server
```

## Monitoring

### View Real-Time Logs
```powershell
# Monitor API logs
Get-Content logs/api.log -Wait -Tail 50

# Monitor training progress
Get-Content logs/training_*.log -Tail 20
```

### Performance Metrics
```bash
# CPU usage
Get-Process | Where-Object {$_.ProcessName -eq 'py'} | Select-Object CPU,WorkingSet

# API statistics
curl http://127.0.0.1:8000/stats
```

## Troubleshooting

### API Won't Start
```powershell
# Check if port is in use
Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue

# Kill existing process
Get-Process | Where-Object {$_.ProcessName -eq 'py'} | Stop-Process -Force

# Check model files exist
Test-Path models/waf_transformer/model.pt
Test-Path models/waf_transformer/encoder
```

### High False Positive Rate
```powershell
# Retrain with more data
py -m model.train `
    --log-dir data/benign_logs `
    --output-dir models/waf_transformer `
    --epochs 15 `
    --batch-size 32 `
    --max-samples 50000 `
    --device cuda

# Or adjust threshold higher
# threshold 0.85 = less sensitive
```

### Slow Performance
```powershell
# Switch to GPU (if available)
$env:WAF_DEVICE="cuda"

# Reduce batch size for API
# Edit api/waf_api.py: BATCH_SIZE = 8

# Clear cache and restart
Remove-Item -Recurse -Force __pycache__
```

## Integration Examples

### Apache ModSecurity Integration
```apache
# /etc/apache2/conf-available/waf.conf
SecRuleEngine On
SecRule REQUEST_URI|REQUEST_HEADERS "@execExternal /usr/local/bin/waf-check.sh" \
    "id:1000,phase:1,deny,status:403,msg:'WAF detected anomaly'"
```

### Nginx Lua Integration
```nginx
location / {
    access_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()
        
        local res, err = httpc:request_uri("http://127.0.0.1:8000/scan", {
            method = "POST",
            body = ngx.req.get_body_data(),
            headers = {
                ["Content-Type"] = "application/json"
            }
        })
        
        if res and res.body then
            local json = require("cjson").decode(res.body)
            if json.is_anomalous then
                ngx.exit(403)
            end
        end
    }
    
    proxy_pass http://backend;
}
```

### Python Integration
```python
import requests

def check_request(method, path, headers):
    """Check if request is anomalous"""
    payload = {
        "method": method,
        "path": path,
        "headers": headers
    }
    
    response = requests.post(
        "http://127.0.0.1:8000/scan",
        json=payload
    )
    
    result = response.json()
    return result["is_anomalous"], result["anomaly_score"]

# Usage
is_attack, score = check_request("GET", "/api/users", {"User-Agent": "Mozilla/5.0"})
if is_attack:
    print(f"Blocked! Anomaly score: {score}")
```

## Backup & Recovery

### Backup Model
```powershell
# Create backup
$date = Get-Date -Format "yyyy-MM-dd"
Copy-Item -Recurse models/waf_transformer models/backups/waf_transformer_$date
```

### Restore Model
```powershell
# Restore from backup
Copy-Item -Recurse models/backups/waf_transformer_2026-01-20 models/waf_transformer -Force
```

## Performance Tuning

### GPU Acceleration
```powershell
# Install CUDA-enabled PyTorch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Verify CUDA
py -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Use GPU
$env:WAF_DEVICE="cuda"
```

### Optimize Batch Size
- **CPU:** 8-16 (current)
- **GPU (8GB):** 32-64
- **GPU (16GB+):** 64-128

### Cache Configuration
```python
# Edit inference/detector.py
# Increase cache size for high traffic
@lru_cache(maxsize=50000)  # Default: 10000
```

## Security Best Practices

1. **Network Security**
   - Run API on localhost for sidecar deployment
   - Use TLS/SSL for remote access
   - Implement API authentication

2. **Input Validation**
   - Already implemented (max sizes enforced)
   - Rate limiting active (100 req/60s)

3. **Logging**
   - Sensitive data already redacted
   - IP addresses hashed with SHA256
   - Structured JSON logging enabled

4. **Model Security**
   - Store models in secure directory
   - Version control model files
   - Regular security updates

## Common Commands Cheat Sheet

```powershell
# Start API
py -m api.waf_api

# Test API
py scripts/test_api.py

# Train model
py -m model.train --log-dir data/benign_logs --epochs 5

# Batch process
py -m ingestion.batch_ingest --input-dir logs/

# Generate test data
py scripts/generate_sample_logs.py --count 5000

# Health check
curl http://127.0.0.1:8000/health

# Scan request
curl -X POST http://127.0.0.1:8000/scan -H "Content-Type: application/json" -d '{"method":"GET","path":"/api/test"}'
```

## Getting Help

- **Documentation:** See README.md, ARCHITECTURE.md
- **Issues:** Check DEPLOYMENT_SUCCESS.md troubleshooting section
- **Logs:** Review logs/ directory for errors
- **Testing:** Run `py scripts/test_api.py` to verify functionality
