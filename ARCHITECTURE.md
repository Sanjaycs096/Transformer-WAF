# System Architecture

## Overview

The Transformer WAF is a production-grade, ML-based anomaly detection system designed to identify malicious HTTP requests by learning normal traffic patterns.

## Core Components

### 1. Data Ingestion Layer

**Modules**: `ingestion/batch_ingest.py`, `ingestion/stream_ingest.py`

- **Batch Ingestion**: Processes historical access logs for training
- **Stream Ingestion**: Tails live logs and sends to API in real-time
- **Supported Formats**: Apache/Nginx combined log format

### 2. Parsing & Normalization Layer

**Modules**: `parsing/log_parser.py`, `parsing/normalizer.py`

- **Log Parser**: Extracts HTTP request components using regex
- **Normalizer**: Removes dynamic tokens (IPs, UUIDs, timestamps) to focus on structural patterns
- **Output**: Standardized request strings ready for tokenization

### 3. Tokenization Layer

**Module**: `tokenization/tokenizer.py`

- **Tokenizer**: Converts normalized requests to BERT-compatible token sequences
- **Max Length**: 128 tokens (configurable)
- **Pretrained**: Uses DistilBERT tokenizer
- **Masking**: Supports MLM for training

### 4. Model Layer

**Modules**: `model/transformer_model.py`, `model/train.py`, `model/fine_tune.py`

- **Architecture**: Transformer autoencoder (encoder + reconstruction head)
- **Base Model**: DistilBERT (66M parameters)
- **Training**: Masked Language Modeling on benign traffic
- **Anomaly Detection**: Reconstruction error + perplexity
- **Fine-tuning**: Incremental learning on new benign data

### 5. Inference Layer

**Module**: `inference/detector.py`

- **Async Detection**: Non-blocking inference using asyncio
- **Batch Support**: Process multiple requests concurrently
- **Scoring**: Combined anomaly score (70% recon error + 30% perplexity)
- **Threshold**: Configurable (default: 0.75)

### 6. API Layer

**Module**: `api/waf_api.py`

- **Framework**: FastAPI with Pydantic validation
- **Endpoints**:
  - `POST /scan`: Single request scanning
  - `POST /batch-scan`: Batch scanning
  - `GET /health`: Health check
  - `GET /stats`: Detection statistics
  - `POST /threshold`: Update threshold
- **Async**: Full async/await support for high concurrency

### 7. Integration Layer

**Configs**: `integration/nginx.conf`, `integration/apache.conf`

- **Nginx**: Traffic mirroring using `mirror` directive
- **Apache**: Proxy configuration with mod_proxy
- **Mode**: Passive monitoring (non-blocking)

## Data Flow

```
Access Logs → Parser → Normalizer → Tokenizer → Model → Anomaly Score → Alert/Log
     ↓                                                           ↓
  (batch)                                                    (if > threshold)
     ↓
  Training
```

## Deployment Architecture

```
┌─────────────────────┐
│   Web Server        │
│  (Nginx/Apache)     │
└──────────┬──────────┘
           │ mirror
           ▼
┌─────────────────────┐     ┌──────────────┐
│   WAF API           │────►│   Model      │
│   (FastAPI)         │     │ (Transformer)│
└──────────┬──────────┘     └──────────────┘
           │
           ▼
┌─────────────────────┐
│   Alert Logger      │
│   (JSON logs)       │
└─────────────────────┘
```

## Training Pipeline

1. **Data Collection**: Gather benign access logs
2. **Preprocessing**: Parse → Normalize → Tokenize
3. **Training**: Masked Language Modeling (10 epochs)
4. **Validation**: Hold-out validation set (10%)
5. **Checkpoint**: Save best model
6. **Deployment**: Load model in API service

## Inference Pipeline

1. **Request Received**: HTTP request arrives at web server
2. **Mirroring**: Copy sent to WAF API
3. **Normalization**: Remove dynamic tokens
4. **Tokenization**: Convert to token IDs
5. **Encoding**: Pass through Transformer
6. **Scoring**: Compute reconstruction error & perplexity
7. **Detection**: Compare to threshold
8. **Logging**: Alert if anomalous

## Continuous Learning

1. **Collection**: Gather new benign traffic (validated)
2. **Fine-tuning**: Incremental training (3 epochs, lower LR)
3. **Validation**: Test on hold-out set
4. **Deployment**: Hot-reload model (no downtime)

## Performance Optimization

- **Batching**: Process multiple requests together
- **Async**: Non-blocking I/O for API calls
- **Thread Pool**: CPU-bound tasks in executor
- **GPU**: Optional CUDA acceleration
- **Caching**: Tokenizer and model loaded once

## Security Considerations

- **Passive Mode**: No request blocking (only monitoring)
- **No Data Storage**: Requests not persisted
- **Model Protection**: Checkpoints contain learned patterns
- **API Auth**: Optional API key support

## Scalability

- **Horizontal**: Multiple API instances behind load balancer
- **Vertical**: GPU for faster inference
- **Batch Size**: Adjust based on throughput requirements
- **Workers**: Uvicorn multi-worker support

## Monitoring

- **Metrics**: RPS, latency, anomaly rate
- **Logs**: Structured JSON logs
- **Alerts**: Anomalous requests logged separately
- **Health**: `/health` endpoint for liveness probes
