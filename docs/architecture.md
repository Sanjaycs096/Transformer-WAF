# System Architecture & Data Flow Diagrams

## Executive Summary

This document describes the complete architecture of the Transformer-based Web Application Firewall (WAF), including:
- Component architecture
- Data flow diagrams (DFDs)
- Technology stack
- Deployment models
- Security boundaries

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Client Layer (Untrusted)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐         ┌──────────────┐       ┌──────────────┐  │
│  │   Web        │         │   Mobile     │       │   API        │  │
│  │   Browser    │         │   App        │       │   Client     │  │
│  └──────┬───────┘         └──────┬───────┘       └──────┬───────┘  │
│         │                        │                       │           │
│         └────────────────────────┼───────────────────────┘           │
│                                  │                                   │
└──────────────────────────────────┼───────────────────────────────────┘
                                   │ HTTPS/TLS
                                   │
┌──────────────────────────────────▼───────────────────────────────────┐
│                        Presentation Layer                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  React Frontend (SPA)                        │   │
│  │                                                               │   │
│  │  ├─ Dashboard       (Metrics, charts, stats)                │   │
│  │  ├─ Live Monitoring (WebSocket real-time stream)            │   │
│  │  ├─ Attack Simulation (Testing interface)                   │   │
│  │  ├─ Analytics       (Historical data)                        │   │
│  │  └─ Documentation   (User guides)                            │   │
│  │                                                               │   │
│  │  Tech: React 18, TypeScript, Tailwind CSS, Axios            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ REST API / WebSocket
                                   │
┌──────────────────────────────────▼───────────────────────────────────┐
│                        Application Layer                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  FastAPI Backend                             │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────────────────────┐ │   │
│  │  │  API Endpoints                                         │ │   │
│  │  │  ├─ /scan         (Single request detection)          │ │   │
│  │  │  ├─ /scan/batch   (Batch processing)                  │ │   │
│  │  │  ├─ /health       (Health check)                      │ │   │
│  │  │  ├─ /stats        (System statistics)                 │ │   │
│  │  │  ├─ /threshold    (Config update)                     │ │   │
│  │  │  ├─ /simulate/attack (Attack testing)                 │ │   │
│  │  │  └─ /ws/live      (WebSocket streaming)               │ │   │
│  │  └────────────────────────────────────────────────────────┘ │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────────────────────┐ │   │
│  │  │  Middleware Stack                                      │ │   │
│  │  │  ├─ CORS Protection                                    │ │   │
│  │  │  ├─ Security Headers                                   │ │   │
│  │  │  ├─ Rate Limiting (100 req/min)                       │ │   │
│  │  │  ├─ Request Validation (Pydantic)                     │ │   │
│  │  │  └─ Error Handling                                     │ │   │
│  │  └────────────────────────────────────────────────────────┘ │   │
│  │                                                               │   │
│  │  Tech: FastAPI 0.128, Pydantic 2.12, Uvicorn                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │            WebSocket Connection Manager                      │   │
│  │  ├─ Connection lifecycle management                          │   │
│  │  ├─ Broadcasting to multiple clients                         │   │
│  │  └─ Keepalive ping/pong (30s timeout)                       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
┌──────────────────────────────────▼───────────────────────────────────┐
│                        ML Inference Layer                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │            Anomaly Detector (AnomalyDetector)                │   │
│  │                                                               │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │  Transformer Model (DistilBERT Autoencoder)         │    │   │
│  │  │  ├─ Encoder: 6 layers, 768 hidden, 12 heads         │    │   │
│  │  │  ├─ Decoder: 6 layers, 768 hidden, 12 heads         │    │   │
│  │  │  ├─ Parameters: 90.7M                                │    │   │
│  │  │  └─ Model Size: 345 MB                               │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │                                                               │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │  Preprocessing Pipeline                              │    │   │
│  │  │  ├─ Tokenization (DistilBERT tokenizer)             │    │   │
│  │  │  ├─ Feature extraction                               │    │   │
│  │  │  ├─ Sequence padding/truncation                      │    │   │
│  │  │  └─ Tensor conversion                                │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │                                                               │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │  Scoring Engine                                      │    │   │
│  │  │  ├─ Reconstruction error (MSE)                       │    │   │
│  │  │  ├─ Perplexity calculation                           │    │   │
│  │  │  ├─ Anomaly score = 0.6*recon + 0.4*perp            │    │   │
│  │  │  └─ Threshold comparison (default: 0.5)             │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │                                                               │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │  Optimizations                                       │    │   │
│  │  │  ├─ JIT compilation (TorchScript)                    │    │   │
│  │  │  ├─ Batch processing (up to 100 requests)           │    │   │
│  │  │  ├─ LRU caching (10,000 entries)                     │    │   │
│  │  │  └─ Thread pool (8 workers)                          │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │                                                               │   │
│  │  Tech: PyTorch 2.10, Transformers 4.37, NumPy              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
┌──────────────────────────────────▼───────────────────────────────────┐
│                        Data Ingestion Layer                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Log Streaming Service                           │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────┐                  │   │
│  │  │  Real Log Streamer                     │                  │   │
│  │  │  ├─ Async file tailing                 │                  │   │
│  │  │  ├─ Apache/Nginx log parsing           │                  │   │
│  │  │  └─ Regex pattern matching             │                  │   │
│  │  └────────────────────────────────────────┘                  │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────┐                  │   │
│  │  │  Simulated Log Streamer (Demo)         │                  │   │
│  │  │  ├─ Generates synthetic traffic         │                  │   │
│  │  │  ├─ 85% benign, 15% attack             │                  │   │
│  │  │  └─ Random delay (0.5-2s)              │                  │   │
│  │  └────────────────────────────────────────┘                  │   │
│  │                                                               │   │
│  │  Tech: aiofiles, asyncio, regex                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
┌──────────────────────────────────▼───────────────────────────────────┐
│                        Storage Layer                                 │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐          ┌──────────────────────┐         │
│  │  Forensic Logs       │          │  ML Models           │         │
│  │                      │          │                      │         │
│  │  Format: JSONL       │          │  Format: .pt/.bin    │         │
│  │  Location: logs/     │          │  Location: models/   │         │
│  │  Rotation: Daily     │          │  Version: 1.0.0      │         │
│  │  Retention: 90 days  │          │  Checkpoints: Yes    │         │
│  └──────────────────────┘          └──────────────────────┘         │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Forensic Log Schema                                          │  │
│  │  {                                                             │  │
│  │    "incident_id": "hash-based UUID",                          │  │
│  │    "timestamp": "ISO 8601 UTC",                               │  │
│  │    "severity": "low|medium|high|critical",                    │  │
│  │    "request_hash": "SHA-256",                                 │  │
│  │    "ip_address_masked": "192.168.***",                        │  │
│  │    "method": "GET|POST|...",                                  │  │
│  │    "path": "/api/endpoint",                                   │  │
│  │    "query_hash": "SHA-256",                                   │  │
│  │    "anomaly_score": 0.0-1.0,                                  │  │
│  │    "is_blocked": true|false,                                  │  │
│  │    "detection_metadata": {...}                                │  │
│  │  }                                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram (DFD) - Level 0 (Context Diagram)

```
                              ┌─────────────┐
                              │   External  │
                              │   Attacker  │
                              └──────┬──────┘
                                     │
                         Malicious   │
                         Requests    │
                                     │
┌──────────────┐                     │                ┌──────────────┐
│              │   HTTP Requests     ▼                │              │
│  Legitimate  ├────────────────►┌───────┐◄───────────┤    Admin    │
│    User      │                 │       │            │    User     │
│              │◄────────────────┤  WAF  │────────────┤              │
└──────────────┘   Filtered/     │       │  Config/   └──────────────┘
                   Protected      └───┬───┘  Monitoring
                   Responses          │
                                      │
                              Anomaly │ Detection
                              Results │
                                      │
                                ┌─────▼─────┐
                                │  Forensic │
                                │   Logs    │
                                └───────────┘
```

---

## Data Flow Diagram (DFD) - Level 1 (System Components)

```
┌───────────┐
│   User    │
└─────┬─────┘
      │ 1. HTTP Request
      ▼
┌─────────────────────────────────────────────────────────────┐
│                    1.0 API Gateway                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Processes:                                            │  │
│  │  • CORS validation                                     │  │
│  │  • Rate limiting check (100 req/min)                  │  │
│  │  • Security headers injection                         │  │
│  │  • Request size validation                            │  │
│  └───────────────────────────────────────────────────────┘  │
└──────┬──────────────────────────────────────────────────────┘
       │ 2. Validated Request
       ▼
┌─────────────────────────────────────────────────────────────┐
│              2.0 Input Validation Layer                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Processes:                                            │  │
│  │  • Pydantic schema validation                         │  │
│  │  • Field-level validators (method, path, headers)     │  │
│  │  • Type coercion and sanitization                     │  │
│  └───────────────────────────────────────────────────────┘  │
└──────┬──────────────────────────────────────────────────────┘
       │ 3. Validated & Normalized Request
       ▼
┌─────────────────────────────────────────────────────────────┐
│                3.0 ML Inference Engine                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Processes:                                            │  │
│  │  • Request → Token sequence                           │  │
│  │  • Transformer encoder pass                           │  │
│  │  • Transformer decoder reconstruction                 │  │
│  │  • MSE + Perplexity calculation                       │  │
│  │  • Anomaly score computation                          │  │
│  │  • Threshold comparison                               │  │
│  └───────────────────────────────────────────────────────┘  │
└──────┬──────────────────────────────────────────────────────┘
       │ 4. Detection Result
       ├───────────────────────────────┐
       │                               │
       ▼                               ▼
┌──────────────────┐          ┌─────────────────────┐
│  4.0 Forensic    │          │  5.0 Response       │
│  Logging         │          │  Builder            │
│                  │          │                     │
│  Processes:      │          │  Processes:         │
│  • PII masking   │          │  • JSON response    │
│  • Hash request  │          │  • HTTP status code │
│  • Classify      │          │  • Error handling   │
│    severity      │          └──────┬──────────────┘
│  • Append log    │                 │
└────────┬─────────┘                 │
         │ 5. Log Entry              │ 6. HTTP Response
         ▼                           ▼
┌─────────────────┐          ┌──────────────┐
│  Forensic Logs  │          │    User      │
│  (JSONL files)  │          └──────────────┘
└─────────────────┘

         ┌────────────────────────────────────┐
         │  6.0 WebSocket Streaming           │
         │  (Parallel Process)                │
         │                                    │
         │  Processes:                        │
         │  • Stream detection results live   │
         │  • Mask sensitive data             │
         │  • Broadcast to all clients        │
         │  • Handle disconnections           │
         └──────┬─────────────────────────────┘
                │ 7. Real-time Events
                ▼
         ┌──────────────┐
         │  Dashboard   │
         │  (WebSocket) │
         └──────────────┘
```

---

## Data Flow Diagram (DFD) - Level 2 (ML Inference Detail)

```
┌──────────────────────────────────────────────────────────────────┐
│              3.0 ML Inference Engine (Detailed)                   │
└──────────────────────────────────────────────────────────────────┘

  Input: {"method": "GET", "path": "/api/users", "query": "?id=1"}
    │
    ▼
┌────────────────────────────────────┐
│  3.1 Request Normalization         │
│  • Concatenate method + path + query
│  • Example: "GET /api/users ?id=1" │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  3.2 Tokenization                  │
│  • DistilBERT tokenizer            │
│  • Convert to token IDs            │
│  • Add [CLS], [SEP] tokens         │
│  • Padding to max_length=128       │
│  Output: tensor([101, 2131, ...])  │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  3.3 Encoder Forward Pass          │
│  • Input: token_ids, attention_mask│
│  • 6 transformer layers            │
│  • Multi-head self-attention (12)  │
│  • Output: hidden_states [768-dim] │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  3.4 Decoder Reconstruction        │
│  • Input: encoder hidden states    │
│  • 6 transformer layers            │
│  • Output: reconstructed logits    │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  3.5 Error Calculation             │
│  • MSE = mean((input - recon)²)    │
│  • Perplexity = exp(cross_entropy) │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  3.6 Anomaly Score                 │
│  • score = 0.6*MSE + 0.4*perplexity│
│  • Normalize to [0, 1]             │
│  • threshold = 0.5 (configurable)  │
│  • is_anomalous = score > threshold│
└────────┬───────────────────────────┘
         │
         ▼
  Output: {
    "anomaly_score": 0.72,
    "is_anomalous": true,
    "threshold": 0.5,
    "reconstruction_error": 0.68,
    "perplexity": 3.24,
    "confidence": 0.85,
    "latency_ms": 12.3
  }
```

---

## Technology Stack

### Backend

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Web Framework** | FastAPI | 0.128.0 | High-performance async API |
| **ASGI Server** | Uvicorn | 0.22.0 | Production server |
| **ML Framework** | PyTorch | 2.10.0 | Deep learning inference |
| **Transformer Library** | Hugging Face Transformers | 4.37.0 | DistilBERT model |
| **Validation** | Pydantic | 2.12.5 | Input validation & serialization |
| **Async I/O** | aiofiles | 23.2.1 | Async file operations |
| **Logging** | structlog | 24.1.0 | Structured logging |

### Frontend

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Framework** | React | 18.2.0 | UI library |
| **Language** | TypeScript | 5.3.3 | Type-safe JavaScript |
| **Build Tool** | Vite | 5.4.21 | Fast bundler |
| **Styling** | Tailwind CSS | 3.3.6 | Utility-first CSS |
| **HTTP Client** | Axios | 1.6.5 | API communication |
| **Icons** | Lucide React | Latest | Icon library |
| **Routing** | React Router | 6.21.1 | SPA routing |

### DevSecOps

| Component | Tool | Purpose |
|-----------|------|---------|
| **SAST** | Bandit | Python security linting |
| **SCA** | Safety, pip-audit | Dependency vulnerability scanning |
| **DAST** | OWASP ZAP | Dynamic security testing |
| **Container Security** | Trivy | Docker image scanning |
| **Secret Scanning** | TruffleHog | Hardcoded secret detection |
| **CI/CD** | GitHub Actions | Automated pipeline |

---

## Deployment Architecture

### Development

```
┌─────────────────────────────────────────────────────────────┐
│                      Local Machine                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐              ┌─────────────┐              │
│  │  Backend    │              │  Frontend   │              │
│  │  :8000      │◄─────────────┤  :3000      │              │
│  └─────────────┘   REST/WS    └─────────────┘              │
│                                                               │
│  Start: start.bat (Windows) or ./start.sh (Linux)           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Production (Docker)

```
┌─────────────────────────────────────────────────────────────────┐
│                      Docker Host                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Reverse Proxy (Nginx)                                     │  │
│  │  :80/:443 → TLS termination                                │  │
│  └───────┬───────────────────────────────────────────────────┘  │
│          │                                                        │
│          ├──────────────────┬─────────────────────────────┐     │
│          │                  │                             │     │
│  ┌───────▼────────┐  ┌──────▼──────┐  ┌──────────────┐   │     │
│  │  Frontend      │  │  Backend    │  │  PostgreSQL  │   │     │
│  │  Container     │  │  Container  │  │  (Optional)  │   │     │
│  │  :80           │  │  :8000      │  │  :5432       │   │     │
│  └────────────────┘  └──────┬──────┘  └──────────────┘   │     │
│                             │                             │     │
│                      ┌──────▼──────┐                      │     │
│                      │  Volume     │                      │     │
│                      │  /models    │                      │     │
│                      │  /logs      │                      │     │
│                      └─────────────┘                      │     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Boundaries

### Trust Zones

```
┌─────────────────────────────────────────────────────────────┐
│  Zone 0: Public Internet (UNTRUSTED)                         │
│  • Clients, attackers, public users                          │
│  • No direct access to internal systems                      │
└──────────────────────┬──────────────────────────────────────┘
                       │ TLS/HTTPS (Production)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│  Zone 1: DMZ - Web Tier (LIMITED TRUST)                      │
│  • React frontend (static files)                             │
│  • Nginx reverse proxy                                       │
│  • Exposed endpoints only                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ Internal Network
                       │
┌──────────────────────▼──────────────────────────────────────┐
│  Zone 2: Application Tier (TRUSTED)                          │
│  • FastAPI backend                                           │
│  • WebSocket server                                          │
│  • Business logic                                            │
│  • Rate limiting, validation                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │ Local/IPC
                       │
┌──────────────────────▼──────────────────────────────────────┐
│  Zone 3: ML Tier (HIGHLY TRUSTED)                            │
│  • Transformer model                                         │
│  • Inference engine                                          │
│  • No network exposure                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │ Filesystem
                       │
┌──────────────────────▼──────────────────────────────────────┐
│  Zone 4: Data Tier (HIGHLY TRUSTED)                          │
│  • Forensic logs (append-only)                               │
│  • Model files (read-only)                                   │
│  • Encrypted at rest (filesystem/OS level)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Performance Characteristics

| Metric | Value | Notes |
|--------|-------|-------|
| **Inference Latency** | 10-15ms | Single request (CPU) |
| **Batch Throughput** | 500+ RPS | 100-request batches (CPU) |
| **Model Load Time** | ~3 seconds | Cold start |
| **Warmup Time** | ~35 seconds | First request |
| **Memory Usage** | ~800 MB | Model + runtime |
| **Concurrent Users** | 100+ | WebSocket connections |

---

## Scalability Considerations

### Horizontal Scaling

- **Stateless API**: No session state, can run multiple instances
- **Load Balancer**: Distribute requests across replicas
- **Model Replication**: Each instance loads its own model copy

### Vertical Scaling

- **GPU Acceleration**: 10-20× faster inference with CUDA
- **Batch Size**: Increase for higher throughput
- **Thread Pool**: Adjust worker count based on CPU cores

---

## Conclusion

This architecture demonstrates:

- ✅ **Separation of Concerns**: Clear layer boundaries
- ✅ **Defense in Depth**: Multiple security layers
- ✅ **Scalability**: Stateless design, async processing
- ✅ **Observability**: Comprehensive logging and monitoring
- ✅ **Production Readiness**: Docker, HTTPS, error handling

The system is academically rigorous, industry-standard, and deployment-ready for real-world WAF applications.
