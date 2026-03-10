#!/bin/bash
#
# Bandit Security Scan - SAST (Static Application Security Testing)
# Scans Python code for security vulnerabilities
#
# Usage: ./bandit_scan.sh

set -e

echo "========================================="
echo "Bandit Security Scan (SAST)"
echo "Secure Software Development - ISRO/DoS"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if bandit is installed
if ! command -v bandit &> /dev/null; then
    echo -e "${YELLOW}Bandit not found. Installing...${NC}"
    pip install bandit bandit-sarif-formatter
fi

# Create reports directory
mkdir -p reports

echo -e "${GREEN}Running Bandit security scan...${NC}"
echo ""

# Run Bandit with comprehensive configuration
bandit -r . \
    --exclude ./venv,./env,./node_modules,./frontend/node_modules,./models,./data \
    --format json \
    --output reports/bandit_report.json \
    --severity-level low \
    --confidence-level low \
    || true  # Don't fail on findings, just report

# Also generate human-readable HTML report
bandit -r . \
    --exclude ./venv,./env,./node_modules,./frontend/node_modules,./models,./data \
    --format html \
    --output reports/bandit_report.html \
    --severity-level low \
    --confidence-level low \
    || true

# Generate SARIF format for GitHub Code Scanning
bandit -r . \
    --exclude ./venv,./env,./node_modules,./frontend/node_modules,./models,./data \
    --format sarif \
    --output reports/bandit_report.sarif \
    --severity-level low \
    --confidence-level low \
    || true

echo ""
echo -e "${GREEN}Scan complete!${NC}"
echo "Reports generated:"
echo "  - reports/bandit_report.json (JSON format)"
echo "  - reports/bandit_report.html (HTML format)"
echo "  - reports/bandit_report.sarif (SARIF for GitHub)"
echo ""

# Parse results and display summary
if [ -f reports/bandit_report.json ]; then
    python3 - <<EOF
import json

with open('reports/bandit_report.json', 'r') as f:
    data = json.load(f)

metrics = data.get('metrics', {})
total_loc = sum(m.get('SLOC', 0) for m in metrics.values())
total_issues = len(data.get('results', []))

severity_counts = {'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
for issue in data.get('results', []):
    sev = issue.get('issue_severity', 'LOW')
    severity_counts[sev] = severity_counts.get(sev, 0) + 1

print("=" * 50)
print("BANDIT SCAN SUMMARY")
print("=" * 50)
print(f"Total Lines of Code Scanned: {total_loc}")
print(f"Total Issues Found: {total_issues}")
print(f"  - HIGH severity: {severity_counts['HIGH']}")
print(f"  - MEDIUM severity: {severity_counts['MEDIUM']}")
print(f"  - LOW severity: {severity_counts['LOW']}")
print("")

if total_issues == 0:
    print("✅ No security issues detected!")
elif severity_counts['HIGH'] > 0:
    print("🔴 CRITICAL: High severity issues found - review immediately!")
    exit(1)
elif severity_counts['MEDIUM'] > 0:
    print("🟡 WARNING: Medium severity issues found - review recommended")
else:
    print("🟢 OK: Only low severity issues found")

print("=" * 50)
EOF
fi

echo ""
echo -e "${GREEN}View detailed report: ${NC}reports/bandit_report.html"
