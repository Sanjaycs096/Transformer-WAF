# Sample Data Generator for Testing

"""
Generates sample access logs for testing the WAF
Run: python scripts/generate_sample_logs.py
"""

import random
from datetime import datetime, timedelta
from pathlib import Path

# Benign traffic patterns
BENIGN_REQUESTS = [
    ('GET', '/api/users', 'page=1&limit=20', 200),
    ('GET', '/api/products', 'category=electronics', 200),
    ('POST', '/api/login', '', 200),
    ('GET', '/api/profile/settings', '', 200),
    ('PUT', '/api/users/profile', '', 200),
    ('GET', '/static/css/main.css', '', 200),
    ('GET', '/static/js/app.js', '', 200),
    ('GET', '/api/orders', 'status=pending', 200),
    ('DELETE', '/api/cart/items/123', '', 204),
    ('GET', '/', '', 200),
]

# Anomalous patterns (for testing detection)
ANOMALOUS_REQUESTS = [
    ('GET', '/admin/shell.php', 'cmd=whoami', 404),
    ('POST', '/api/login', "username=admin' OR '1'='1", 400),
    ('GET', '/../../../etc/passwd', '', 404),
    ('POST', '/upload.php', 'file=shell.php', 403),
    ('GET', '/api/users', 'id=1 UNION SELECT * FROM passwords', 400),
]

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    'curl/7.68.0',
    'PostmanRuntime/7.26.8',
    'Python-urllib/3.8',
]

def generate_log_line(method, path, query, status, ip, timestamp, user_agent):
    """Generate Apache/Nginx combined log format line"""
    size = random.randint(100, 5000)
    uri = f"{path}?{query}" if query else path

    return (
        f'{ip} - - [{timestamp}] '
        f'"{method} {uri} HTTP/1.1" {status} {size} '
        f'"-" "{user_agent}"'
    )

def generate_sample_logs(output_file, num_benign=1000, num_anomalous=50):
    """Generate sample access logs"""

    Path(output_file).parent.mkdir(parents=True, exist_ok=True)

    with open(output_file, 'w') as f:
        base_time = datetime.now() - timedelta(hours=24)

        # Generate benign traffic
        for i in range(num_benign):
            method, path, query, status = random.choice(BENIGN_REQUESTS)
            ip = f"192.168.1.{random.randint(1, 254)}"
            timestamp = (base_time + timedelta(seconds=i * 86400 / num_benign)).strftime('%d/%b/%Y:%H:%M:%S +0000')
            user_agent = random.choice(USER_AGENTS)

            line = generate_log_line(method, path, query, status, ip, timestamp, user_agent)
            f.write(line + '\n')

        # Generate anomalous traffic
        for i in range(num_anomalous):
            method, path, query, status = random.choice(ANOMALOUS_REQUESTS)
            ip = f"10.0.0.{random.randint(1, 254)}"
            timestamp = (base_time + timedelta(seconds=random.randint(0, 86400))).strftime('%d/%b/%Y:%H:%M:%S +0000')
            user_agent = random.choice(['sqlmap/1.0', 'Nikto/2.1.6', 'masscan/1.0'])

            line = generate_log_line(method, path, query, status, ip, timestamp, user_agent)
            f.write(line + '\n')

    print(f"Generated {num_benign} benign + {num_anomalous} anomalous requests")
    print(f"Saved to: {output_file}")

if __name__ == "__main__":
    # Generate training data (benign only)
    generate_sample_logs("data/benign_logs/sample_benign.log", num_benign=5000, num_anomalous=0)

    # Generate test data (mixed)
    generate_sample_logs("data/test_logs/sample_mixed.log", num_benign=1000, num_anomalous=100)
