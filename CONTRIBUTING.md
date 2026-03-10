# Contributing to Transformer WAF

Thank you for your interest in contributing to the Transformer-based Web Application Firewall project! This document provides guidelines for contributing to this **academic project** developed for **ISRO / Department of Space** evaluation.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Security Guidelines](#security-guidelines)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Academic Contributions](#academic-contributions)

---

## Code of Conduct

### Our Standards

- **Security First**: All contributions must maintain or improve security posture
- **Quality Code**: Follow Python PEP 8 and TypeScript best practices
- **Academic Rigor**: Document security considerations and design decisions
- **Respect**: Be respectful and constructive in all interactions

### Prohibited Actions

- Introducing security vulnerabilities
- Bypassing security controls
- Committing secrets or credentials
- Plagiarizing code without attribution

---

## Getting Started

### Prerequisites

- Python 3.10+
- Node.js 18+
- Docker 24+
- Git
- Virtual environment (venv or conda)

### Development Setup

```bash
# Clone repository
git clone https://github.com/your-org/transformer-waf.git
cd transformer-waf

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development tools

# Install frontend dependencies
cd frontend
npm install
cd ..

# Run tests to verify setup
pytest
```

---

## Development Workflow

### 1. Branch Naming Convention

```
feature/<feature-name>      # New features
fix/<bug-name>              # Bug fixes
security/<vulnerability>    # Security patches
docs/<section>              # Documentation updates
refactor/<component>        # Code refactoring
```

**Examples**:
- `feature/websocket-support`
- `security/fix-xss-vulnerability`
- `docs/update-api-reference`

### 2. Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `security`: Security patch
- `docs`: Documentation
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `chore`: Build/tooling changes

**Examples**:
```
feat(detector): add ensemble scoring with Mahalanobis distance

security(api): fix rate limiting bypass vulnerability
Closes #123

docs(readme): update installation instructions for Windows
```

### 3. Development Process

1. **Create branch** from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature
   ```

2. **Make changes** following coding standards

3. **Run tests** and ensure they pass:
   ```bash
   pytest --cov
   ```

4. **Run security scans**:
   ```bash
   bash devsecops/bandit_scan.sh
   ```

5. **Commit changes**:
   ```bash
   git add .
   git commit -m "feat(component): description"
   ```

6. **Push to remote**:
   ```bash
   git push origin feature/your-feature
   ```

7. **Create Pull Request** to `develop` branch

---

## Coding Standards

### Python Code Style

Follow **PEP 8** with these specifics:

- **Line length**: 100 characters (not 79)
- **Imports**: Grouped and sorted (use `isort`)
- **Type hints**: Required for all functions
- **Docstrings**: Google style for all public functions

**Example**:
```python
from typing import List, Dict, Optional
import torch

def detect_anomaly(
    request: Dict[str, str],
    threshold: float = 0.75
) -> Dict[str, float]:
    """Detect anomaly in HTTP request.
    
    Args:
        request: HTTP request dictionary with method, path, headers
        threshold: Anomaly score threshold (0.0 to 1.0)
    
    Returns:
        Dictionary containing anomaly_score and is_anomalous
        
    Raises:
        ValueError: If request is invalid
    """
    # Implementation
    pass
```

### TypeScript Code Style

- **ESLint**: Follow Airbnb style guide
- **Prettier**: Auto-format on save
- **Type safety**: Strict mode enabled
- **Naming**: camelCase for variables, PascalCase for components

**Example**:
```typescript
interface ScanResult {
  anomalyScore: number;
  isAnomalous: boolean;
  timestamp: string;
}

const scanRequest = async (
  request: HTTPRequest
): Promise<ScanResult> => {
  // Implementation
};
```

### Code Quality Tools

Run before committing:

```bash
# Python
black .                    # Auto-format
isort .                    # Sort imports
flake8 .                   # Linting
mypy .                     # Type checking

# TypeScript
cd frontend
npm run lint               # ESLint
npm run format             # Prettier
```

---

## Security Guidelines

### OWASP Secure Coding Practices

1. **Input Validation**
   - Validate all user inputs (Pydantic schemas)
   - Sanitize for XSS, SQL injection
   - Example:
     ```python
     from pydantic import BaseModel, validator
     
     class HTTPRequest(BaseModel):
         method: str
         path: str
         
         @validator('method')
         def validate_method(cls, v):
             allowed = ['GET', 'POST', 'PUT', 'DELETE']
             if v not in allowed:
                 raise ValueError(f'Invalid method: {v}')
             return v
     ```

2. **Output Encoding**
   - Encode HTML, JavaScript, SQL in responses
   - Use Jinja2 auto-escaping

3. **Authentication & Authorization**
   - Never hardcode credentials
   - Use environment variables
   - Implement API key rotation

4. **Sensitive Data**
   - Never log passwords, tokens, PII
   - Use PII masking:
     ```python
     from utils.logger import mask_pii
     
     logger.info(f"Request from {mask_pii(ip_address)}")
     ```

5. **Cryptography**
   - Use TLS 1.3 for production
   - No MD5 or SHA1 for hashing
   - Example:
     ```python
     import hashlib
     
     # Good
     hash_value = hashlib.sha256(data.encode()).hexdigest()
     
     # Bad
     # hash_value = hashlib.md5(data.encode()).hexdigest()
     ```

### Security Checklist

Before submitting PR:

- [ ] No hardcoded secrets or credentials
- [ ] Input validation for all user inputs
- [ ] PII masking in logs
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] HTTPS used in production configs
- [ ] Dependencies are up-to-date
- [ ] Bandit scan passes (0 HIGH findings)

---

## Testing Requirements

### Coverage Requirements

- **Minimum coverage**: 80%
- **Critical paths**: 95%+ (detector, API endpoints)

### Test Types

1. **Unit Tests** (pytest)
   ```python
   def test_anomaly_detection():
       detector = AnomalyDetector()
       result = detector.detect(benign_request)
       assert result['is_anomalous'] == False
   ```

2. **Integration Tests**
   ```python
   def test_api_endpoint():
       response = client.post('/scan', json=request_data)
       assert response.status_code == 200
   ```

3. **Security Tests**
   ```python
   def test_sql_injection_detection():
       malicious_request = {
           'path': "/users?id=1' OR '1'='1"
       }
       result = detector.detect(malicious_request)
       assert result['is_anomalous'] == True
   ```

### Running Tests

```bash
# All tests with coverage
pytest --cov=. --cov-report=html --cov-report=term

# Specific test file
pytest tests/test_detector.py -v

# With parallel execution
pytest -n auto
```

---

## Documentation

### Code Documentation

- **Docstrings**: Required for all public functions/classes
- **Inline comments**: For complex logic only
- **Type hints**: Required

### Project Documentation

When adding features, update:

1. **README.md**: If adding user-facing features
2. **API documentation**: For new endpoints
3. **Security documentation**: For security features
   - `security/threat_modeling.md`: New threats
   - `security/compliance_mapping.md`: Compliance impact

### Examples

Good documentation:
```python
def ensemble_score(
    reconstruction_error: float,
    perplexity: float,
    attention_anomaly: float,
    mahalanobis_distance: float
) -> float:
    """Calculate ensemble anomaly score from multiple metrics.
    
    Uses weighted average with empirically determined weights:
    - Reconstruction Error: 35%
    - Perplexity: 30%
    - Attention Anomaly: 20%
    - Mahalanobis Distance: 15%
    
    Args:
        reconstruction_error: MSE between input and reconstruction (0.0-1.0)
        perplexity: Model perplexity score (1.0+)
        attention_anomaly: Attention pattern deviation (0.0-1.0)
        mahalanobis_distance: Statistical distance from benign distribution
        
    Returns:
        Ensemble score (0.0-1.0), higher indicates more anomalous
        
    Example:
        >>> ensemble_score(0.15, 1.2, 0.1, 0.05)
        0.125
    """
    weights = [0.35, 0.30, 0.20, 0.15]
    scores = [reconstruction_error, perplexity, attention_anomaly, mahalanobis_distance]
    return sum(w * s for w, s in zip(weights, scores))
```

---

## Pull Request Process

### Before Submitting

1. ✅ All tests pass (`pytest`)
2. ✅ Coverage meets requirements (80%+)
3. ✅ Security scans pass (Bandit 0 HIGH)
4. ✅ Code formatted (`black`, `isort`)
5. ✅ Linting passes (`flake8`, `mypy`)
6. ✅ Documentation updated
7. ✅ Commits follow conventional format

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change
- [ ] Security patch
- [ ] Documentation update

## Security Considerations
Describe security impact (if any)

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass (80%+ coverage)
- [ ] Security scans pass
- [ ] No hardcoded secrets

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks**: GitHub Actions runs 8-job pipeline
2. **Code Review**: At least 1 approval required
3. **Security Review**: Required for security-related changes
4. **Merge**: Squash and merge to `develop`

---

## Academic Contributions

This project demonstrates **Secure Software Development** principles for academic evaluation.

### Areas for Academic Enhancement

1. **Threat Modeling**
   - Add new STRIDE threats to `security/threat_modeling.md`
   - Update DREAD scores with justifications

2. **Compliance Mapping**
   - Map to additional frameworks (e.g., CIS Controls)
   - Document control implementations

3. **ML Improvements**
   - Enhance ensemble scoring algorithm
   - Add new anomaly detection metrics
   - Improve model explainability (SHAP/LIME)

4. **Performance Optimization**
   - Reduce inference latency
   - Improve throughput
   - Optimize memory usage

5. **Testing**
   - Add attack test cases
   - Increase coverage for edge cases
   - Adversarial robustness testing

### Citation

When referencing this work:

```
Transformer-based Web Application Firewall
ISRO / Department of Space Academic Project
Secure Software Development Course
[Your University], 2025
```

---

## Questions?

For questions or clarifications:

- **Email**: [your-email@example.com]
- **GitHub Issues**: [Link to issues]
- **Academic Advisor**: Dr. [Advisor Name]

---

**Thank you for contributing to secure India's space infrastructure! 🚀🛡️**
