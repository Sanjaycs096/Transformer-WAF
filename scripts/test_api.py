# Test API with sample requests

"""
Simple test script for WAF API
Run: python scripts/test_api.py
"""

import requests
import json
from datetime import datetime

API_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("Testing /health endpoint...")
    response = requests.get(f"{API_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}\n")

def test_scan(method, path, query=""):
    """Test scan endpoint"""
    print(f"Testing scan: {method} {path}?{query}")

    data = {
        "method": method,
        "path": path,
        "query_string": query,
        "headers": {"User-Agent": "Mozilla/5.0"},
        "body": ""
    }

    response = requests.post(f"{API_URL}/scan", json=data)
    result = response.json()

    print(f"Anomaly Score: {result['anomaly_score']:.4f}")
    print(f"Is Anomalous: {result['is_anomalous']}")
    print(f"Threshold: {result['threshold']}\n")

    return result

def test_batch_scan():
    """Test batch scan endpoint"""
    print("Testing /batch-scan endpoint...")

    requests_data = [
        {"method": "GET", "path": "/api/users", "query_string": "page=1", "headers": {}, "body": ""},
        {"method": "POST", "path": "/admin/shell.php", "query_string": "cmd=ls", "headers": {}, "body": ""},
        {"method": "GET", "path": "/api/products", "query_string": "id=123", "headers": {}, "body": ""},
    ]

    response = requests.post(f"{API_URL}/batch-scan", json={"requests": requests_data})
    result = response.json()

    print(f"Total Requests: {result['total_requests']}")
    print(f"Anomalous Count: {result['anomalous_count']}")
    print(f"\nDetailed Results:")
    for i, res in enumerate(result['results']):
        print(f"  Request {i+1}: Score={res['anomaly_score']:.4f}, Anomalous={res['is_anomalous']}")
    print()

def test_stats():
    """Test stats endpoint"""
    print("Testing /stats endpoint...")
    response = requests.get(f"{API_URL}/stats")
    print(f"Stats: {json.dumps(response.json(), indent=2)}\n")

if __name__ == "__main__":
    print("=" * 60)
    print("WAF API Test Suite")
    print("=" * 60 + "\n")

    try:
        # Test health
        test_health()

        # Test benign requests
        print("BENIGN REQUESTS:")
        print("-" * 60)
        test_scan("GET", "/api/users", "page=1&limit=20")
        test_scan("POST", "/api/login")
        test_scan("GET", "/static/css/main.css")

        # Test suspicious requests
        print("\nSUSPICIOUS REQUESTS:")
        print("-" * 60)
        test_scan("GET", "/admin/shell.php", "cmd=whoami")
        test_scan("POST", "/api/login", "username=admin' OR '1'='1")
        test_scan("GET", "/../../../etc/passwd")

        # Test batch scan
        print("\nBATCH SCAN:")
        print("-" * 60)
        test_batch_scan()

        # Test stats
        test_stats()

        print("=" * 60)
        print("All tests completed!")
        print("=" * 60)

    except requests.exceptions.ConnectionError:
        print("ERROR: Cannot connect to API. Make sure it's running:")
        print("  python -m api.waf_api")
    except Exception as e:
        print(f"ERROR: {e}")
