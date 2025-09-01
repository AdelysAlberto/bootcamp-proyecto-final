# Makefile for Reto Final Python Project
# DevOps Bootcamp Final Challenge

# Variables
PYTHON := python
PIP := pip
PYTEST := pytest
DOCKER := docker
DOCKER_COMPOSE := docker-compose
PROJECT_NAME := reto-final-python
VENV_DIR := venv
COVERAGE_MIN := 85

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

.PHONY: help setup install clean lint typecheck test test-unit test-integration test-coverage build run docker-build docker-run docker-compose-up docker-compose-down deploy pre-commit install-hooks ci

## Help
help: ## Display this help message
	@echo "$(BLUE)Reto Final Python - DevOps Bootcamp$(NC)"
	@echo "$(BLUE)====================================$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Usage: make <target>$(NC)"

## Setup and Installation
setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	$(PYTHON) -m venv $(VENV_DIR)
	@echo "$(GREEN)Virtual environment created. Activate with: source $(VENV_DIR)/bin/activate$(NC)"

install: ## Install dependencies
	@echo "$(BLUE)Installing dependencies...$(NC)"
	$(PYTHON) -m pip install --upgrade pip
	@if [ -f pyproject.toml ]; then \
		echo "$(YELLOW)Installing from pyproject.toml...$(NC)"; \
		$(PIP) install -e ".[dev,test]"; \
	else \
		echo "$(YELLOW)Installing from requirements files...$(NC)"; \
		$(PIP) install -r requirements.txt; \
		[ -f requirements-dev.txt ] && $(PIP) install -r requirements-dev.txt || true; \
	fi
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

install-hooks: ## Install pre-commit hooks
	@echo "$(BLUE)Installing pre-commit hooks...$(NC)"
	pre-commit install
	@echo "$(GREEN)Pre-commit hooks installed!$(NC)"

## Code Quality
lint: ## Run linting with ruff and black
	@echo "$(BLUE)Running code quality checks...$(NC)"
	@echo "$(YELLOW)Running ruff linter...$(NC)"
	ruff check .
	@echo "$(YELLOW)Running ruff formatter...$(NC)"
	ruff format --check .
	@echo "$(YELLOW)Running black formatter check...$(NC)"
	black --check .
	@echo "$(GREEN)Linting completed successfully!$(NC)"

lint-fix: ## Fix linting issues automatically
	@echo "$(BLUE)Fixing linting issues...$(NC)"
	ruff check --fix .
	ruff format .
	black .
	@echo "$(GREEN)Linting issues fixed!$(NC)"

typecheck: ## Run type checking with mypy
	@echo "$(BLUE)Running type checking...$(NC)"
	mypy app/
	@echo "$(GREEN)Type checking completed!$(NC)"

security: ## Run security checks
	@echo "$(BLUE)Running security checks...$(NC)"
	@echo "$(YELLOW)Installing security tools...$(NC)"
	$(PIP) install bandit safety || true
	@echo "$(YELLOW)Running bandit security scan...$(NC)"
	bandit -r app/ || true
	@echo "$(YELLOW)Running safety dependency check...$(NC)"
	safety check || true
	@echo "$(GREEN)Security checks completed!$(NC)"

## Testing
test: ## Run all tests with coverage
	@echo "$(BLUE)Running all tests with coverage...$(NC)"
	chmod +x test.sh
	./test.sh -v -c $(COVERAGE_MIN)
	@echo "$(GREEN)All tests completed successfully!$(NC)"

test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	chmod +x test.sh
	./test.sh -u -v
	@echo "$(GREEN)Unit tests completed!$(NC)"

test-integration: ## Run integration tests only
	@echo "$(BLUE)Running integration tests...$(NC)"
	chmod +x test.sh
	./test.sh -i -v
	@echo "$(GREEN)Integration tests completed!$(NC)"

test-coverage: ## Generate HTML coverage report
	@echo "$(BLUE)Generating coverage report...$(NC)"
	chmod +x test.sh
	./test.sh -r html -c $(COVERAGE_MIN)
	@echo "$(GREEN)Coverage report generated: htmlcov/index.html$(NC)"

test-fast: ## Run tests without coverage for quick feedback
	@echo "$(BLUE)Running fast tests...$(NC)"
	$(PYTEST) -q --maxfail=1 --disable-warnings
	@echo "$(GREEN)Fast tests completed!$(NC)"

## Application
run: ## Run the Flask application locally
	@echo "$(BLUE)Starting Flask application...$(NC)"
	$(PYTHON) run.py

run-dev: ## Run application in development mode
	@echo "$(BLUE)Starting Flask application in development mode...$(NC)"
	FLASK_ENV=development $(PYTHON) run.py

## Docker Operations
docker-build: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	$(DOCKER) build -t $(PROJECT_NAME):latest .
	@echo "$(GREEN)Docker image built successfully!$(NC)"

docker-run: ## Run application in Docker container
	@echo "$(BLUE)Running application in Docker...$(NC)"
	$(DOCKER) run --rm -p 5000:5000 --name $(PROJECT_NAME) $(PROJECT_NAME):latest

docker-test: ## Test Docker image
	@echo "$(BLUE)Testing Docker image...$(NC)"
	$(DOCKER) run --rm -d --name test-$(PROJECT_NAME) -p 5001:5000 $(PROJECT_NAME):latest
	sleep 10
	curl -f http://localhost:5001/health || ($(DOCKER) logs test-$(PROJECT_NAME) && exit 1)
	$(DOCKER) stop test-$(PROJECT_NAME)
	@echo "$(GREEN)Docker image tested successfully!$(NC)"

## Docker Compose Operations
compose-up: ## Start all services with docker-compose
	@echo "$(BLUE)Starting services with docker-compose...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Services started! Check: http://localhost:5001$(NC)"

compose-down: ## Stop all services
	@echo "$(BLUE)Stopping services...$(NC)"
	$(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "$(GREEN)Services stopped!$(NC)"

compose-logs: ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

compose-build: ## Build services with docker-compose
	@echo "$(BLUE)Building services with docker-compose...$(NC)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Services built successfully!$(NC)"

## CI/CD Operations
ci: ## Run CI pipeline locally
	@echo "$(BLUE)Running CI pipeline locally...$(NC)"
	@echo "$(YELLOW)Step 1: Code quality checks...$(NC)"
	$(MAKE) lint
	@echo "$(YELLOW)Step 2: Type checking...$(NC)"
	$(MAKE) typecheck
	@echo "$(YELLOW)Step 3: Security checks...$(NC)"
	$(MAKE) security
	@echo "$(YELLOW)Step 4: Running tests...$(NC)"
	$(MAKE) test
	@echo "$(YELLOW)Step 5: Building Docker image...$(NC)"
	$(MAKE) docker-build
	@echo "$(YELLOW)Step 6: Testing Docker image...$(NC)"
	$(MAKE) docker-test
	@echo "$(GREEN)CI pipeline completed successfully!$(NC)"

pre-commit: ## Run pre-commit on all files
	@echo "$(BLUE)Running pre-commit hooks...$(NC)"
	pre-commit run --all-files
	@echo "$(GREEN)Pre-commit checks completed!$(NC)"

## Cleanup
clean: ## Clean up temporary files and caches
	@echo "$(BLUE)Cleaning up...$(NC)"
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .mypy_cache .ruff_cache .coverage htmlcov/ reports/
	rm -f coverage.xml *.log
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-docker: ## Clean up Docker resources
	@echo "$(BLUE)Cleaning Docker resources...$(NC)"
	$(DOCKER) system prune -f --filter "until=24h" || true
	$(DOCKER) image prune -f || true
	@echo "$(GREEN)Docker cleanup completed!$(NC)"

clean-all: clean clean-docker ## Full cleanup including Docker
	@echo "$(GREEN)Full cleanup completed!$(NC)"

## Development helpers
dev-setup: setup install install-hooks ## Complete development setup
	@echo "$(GREEN)Development environment setup completed!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Activate virtual environment: source $(VENV_DIR)/bin/activate"
	@echo "  2. Run tests: make test"
	@echo "  3. Start application: make run"

status: ## Show project status
	@echo "$(BLUE)Project Status$(NC)"
	@echo "=============="
	@echo "Python version: $$($(PYTHON) --version)"
	@echo "Pip version: $$($(PIP) --version)"
	@echo "Virtual env: $$(if [ -n "$$VIRTUAL_ENV" ]; then echo "$$VIRTUAL_ENV"; else echo "Not activated"; fi)"
	@echo "Docker: $$($(DOCKER) --version 2>/dev/null || echo "Not available")"
	@echo "Git branch: $$(git branch --show-current 2>/dev/null || echo "Not a git repository")"
	@echo "Git status: $$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') modified files"
