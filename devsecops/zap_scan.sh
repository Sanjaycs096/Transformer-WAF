#!/bin/bash
#
# OWASP ZAP Scan - DAST (Dynamic Application Security Testing)
# Scans running application for security vulnerabilities
#
# Prerequisites: 
#  - WAF API must be running on http://127.0.0.1:8000
#  - Docker installed (for ZAP container)
#
# Usage: ./zap_scan.sh

set -e

echo "========================================="
echo "OWASP ZAP Security Scan (DAST)"
echo "Secure Software Development - ISRO/DoS"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TARGET_URL="http://host.docker.internal:8000"  # Docker host networking
ZAP_IMAGE="owasp/zap2docker-stable"
REPORTS_DIR="reports"

# Create reports directory
mkdir -p $REPORTS_DIR

# Check if API is running
echo -e "${YELLOW}Checking if WAF API is running...${NC}"
if ! curl -s http://127.0.0.1:8000/health > /dev/null; then
    echo -e "${RED}ERROR: WAF API is not running!${NC}"
    echo "Please start the API first:"
    echo "  python -m api.waf_api"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Pull latest ZAP image
echo -e "${YELLOW}Pulling OWASP ZAP Docker image...${NC}"
docker pull $ZAP_IMAGE

echo ""
echo -e "${GREEN}Running ZAP Baseline Scan...${NC}"
echo "Target: $TARGET_URL"
echo ""

# Run ZAP baseline scan
# This is a passive scan + spider - safe for testing
docker run --rm \
    -v "$(pwd)/$REPORTS_DIR:/zap/wrk/:rw" \
    -t $ZAP_IMAGE \
    zap-baseline.py \
    -t $TARGET_URL \
    -r zap_baseline_report.html \
    -J zap_baseline_report.json \
    -w zap_baseline_report.md \
    -g gen.conf \
    -I \
    || true  # Don't fail on findings

echo ""
echo -e "${GREEN}Running ZAP API Scan...${NC}"
echo ""

# Run ZAP API scan with OpenAPI/Swagger spec
# More thorough than baseline, tests all API endpoints
docker run --rm \
    -v "$(pwd)/$REPORTS_DIR:/zap/wrk/:rw" \
    -t $ZAP_IMAGE \
    zap-api-scan.py \
    -t $TARGET_URL \
    -f openapi \
    -r zap_api_report.html \
    -J zap_api_report.json \
    -w zap_api_report.md \
    -I \
    || true

echo ""
echo -e "${GREEN}Scan complete!${NC}"
echo "Reports generated:"
echo "  - $REPORTS_DIR/zap_baseline_report.html"
echo "  - $REPORTS_DIR/zap_baseline_report.json"
echo "  - $REPORTS_DIR/zap_api_report.html"
echo "  - $REPORTS_DIR/zap_api_report.json"
echo ""

# Parse and display summary
if [ -f "$REPORTS_DIR/zap_baseline_report.json" ]; then
    python3 - <<EOF
import json
import os

report_file = "$REPORTS_DIR/zap_baseline_report.json"
if os.path.exists(report_file):
    with open(report_file, 'r') as f:
        data = json.load(f)
    
    site = data.get('site', [{}])[0]
    alerts = site.get('alerts', [])
    
    risk_counts = {'High': 0, 'Medium': 0, 'Low': 0, 'Informational': 0}
    for alert in alerts:
        risk = alert.get('riskdesc', 'Low').split()[0]
        risk_counts[risk] = risk_counts.get(risk, 0) + 1
    
    print("=" * 50)
    print("ZAP SCAN SUMMARY")
    print("=" * 50)
    print(f"Total Alerts: {len(alerts)}")
    print(f"  - High Risk: {risk_counts['High']}")
    print(f"  - Medium Risk: {risk_counts['Medium']}")
    print(f"  - Low Risk: {risk_counts['Low']}")
    print(f"  - Informational: {risk_counts['Informational']}")
    print("")
    
    if risk_counts['High'] > 0:
        print("🔴 CRITICAL: High risk vulnerabilities found!")
        print("Action required: Review and remediate immediately")
    elif risk_counts['Medium'] > 0:
        print("🟡 WARNING: Medium risk vulnerabilities found")
        print("Action required: Review and plan remediation")
    else:
        print("🟢 OK: No high/medium risk vulnerabilities detected")
    
    print("=" * 50)
EOF
fi

echo ""
echo -e "${GREEN}View detailed report: ${NC}$REPORTS_DIR/zap_baseline_report.html"
