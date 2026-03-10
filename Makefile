# Makefile for Transformer WAF

.PHONY: help install train api test clean docker

help:
	@echo "Transformer WAF - Makefile Commands"
	@echo "===================================="
	@echo "install          Install dependencies"
	@echo "generate-data    Generate sample logs for testing"
	@echo "train            Train the model on sample data"
	@echo "api              Start the API service"
	@echo "test             Run API tests"
	@echo "docker-build     Build Docker image"
	@echo "docker-up        Start Docker containers"
	@echo "docker-down      Stop Docker containers"
	@echo "clean            Clean generated files"

install:
	pip install -r requirements.txt

generate-data:
	python scripts/generate_sample_logs.py

train:
	python -m model.train \
		--log-dir data/benign_logs \
		--output-dir models/waf_transformer \
		--epochs 5 \
		--batch-size 32 \
		--max-samples 5000

api:
	python -m api.waf_api --host 0.0.0.0 --port 8000

test:
	python scripts/test_api.py

docker-build:
	cd docker && docker-compose build

docker-up:
	cd docker && docker-compose up -d

docker-down:
	cd docker && docker-compose down

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf build/ dist/ *.egg-info
	rm -rf logs/*.log logs/*.jsonl
