"""
Transformer WAF - Setup Configuration
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

# Read requirements
requirements_file = Path(__file__).parent / "requirements.txt"
requirements = []
if requirements_file.exists():
    with open(requirements_file, 'r', encoding='utf-8') as f:
        requirements = [
            line.strip() 
            for line in f 
            if line.strip() and not line.startswith('#')
        ]

setup(
    name="transformer-waf",
    version="1.0.0",
    description="Production-grade Transformer-based Web Application Firewall for anomaly detection",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="ISRO / Department of Space",
    author_email="cybersec@isro.gov.in",
    url="https://github.com/isro/transformer-waf",
    packages=find_packages(exclude=["tests", "tests.*", "docker", "integration"]),
    python_requires=">=3.10",
    install_requires=requirements,
    extras_require={
        "dev": [
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.4.0",
            "pytest>=7.4.0",
            "pytest-asyncio>=0.21.0",
            "pytest-cov>=4.1.0",
        ],
        "gpu": [
            "torch-cuda>=2.0.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "waf-train=model.train:main",
            "waf-finetune=model.fine_tune:main",
            "waf-api=api.waf_api:main",
            "waf-ingest-batch=ingestion.batch_ingest:main",
            "waf-ingest-stream=ingestion.stream_ingest:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Information Technology",
        "Topic :: Security",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: Other/Proprietary License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Operating System :: OS Independent",
    ],
    keywords="waf security anomaly-detection transformer deep-learning cybersecurity",
    project_urls={
        "Documentation": "https://github.com/isro/transformer-waf/wiki",
        "Source": "https://github.com/isro/transformer-waf",
        "Tracker": "https://github.com/isro/transformer-waf/issues",
    },
)
