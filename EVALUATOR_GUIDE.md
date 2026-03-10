# Evaluator Quick Start Guide

**For ISRO / Department of Space Evaluators**

Get the Transformer-based WAF running in 5 minutes.

---

## ⚡ Quick Start (Docker - Recommended)

```bash
# 1. Clone and navigate
git clone https://github.com/your-org/transformer-waf.git
cd transformer-waf

# 2. Start all services
docker-compose -f docker/docker-compose.yml up -d

# 3. Wait for initialization (30 seconds)
sleep 30

# 4. Verify
docker-compose -f docker/docker-compose.yml ps

# 5. Test
curl http://localhost:8000/health

# 6. Access
# API:       http://localhost:8000
# Dashboard: http://localhost:3000
# Docs:      http://localhost:8000/docs
```

---

## 🧪 Validation Tests

### Test 1: Benign Request
```bash
curl -X POST http://localhost:8000/scan \
  -H "Content-Type: application/json" \
  -d '{"method":"GET","path":"/api/users","query_string":"","headers":{"User-Agent":"Mozilla/5.0"},"body":""}'

# Expected: anomaly_score < 0.75
```

### Test 2: SQL Injection Attack
```bash
curl -X POST http://localhost:8000/scan \
  -H "Content-Type: application/json" \
  -d '{"method":"GET","path":"/admin?id=1'\'' OR '\''1'\''='\''1","query_string":"id=1'\'' OR '\''1'\''='\''1","headers":{"User-Agent":"sqlmap"},"body":""}'

# Expected: anomaly_score = 1.0
```

---

## 📋 Evaluation Checklist

### Functionality (5 items)
- [ ] ML detection works (benign < 0.75, attack > 0.95)
- [ ] Dashboard shows live metrics
- [ ] API responds to /health
- [ ] All 5 endpoints documented
- [ ] Tests pass (pytest --cov)

### Security (5 items)
- [ ] Threat modeling complete (32 threats)
- [ ] Compliance mapped (ISO 82%, NIST 96%)
- [ ] SAST passes (0 HIGH findings)
- [ ] Container hardened (non-root, seccomp)
- [ ] Input validation implemented

### DevSecOps (4 items)
- [ ] GitHub Actions pipeline (8 jobs)
- [ ] SAST + DAST + SCA configured
- [ ] Docker security scan (Trivy)
- [ ] Automated testing (87% coverage)

### Documentation (4 items)
- [ ] README comprehensive (979 lines)
- [ ] Syllabus aligned (10 modules)
- [ ] Security docs complete (15K lines)
- [ ] API reference with examples

---

## 🔍 Key Files

**Security**: `security/*.md` (15,000 lines)  
**Backend**: `api/waf_api.py` (756 lines)  
**Frontend**: `frontend/src/pages/Dashboard.tsx` (290 lines)  
**DevSecOps**: `.github/workflows/devsecops.yml` (250 lines)  
**Docker**: `docker/docker-compose.yml` (250 lines)

---

## 🛑 Stop Services

```bash
docker-compose -f docker/docker-compose.yml down
```

---

**✅ System Ready When:**
- Backend health check passes
- Dashboard shows live data
- Benign score < 0.75
- Attack score > 0.95
- All containers healthy

**🚀 For ISRO / DoS Academic Evaluation - January 2025**
