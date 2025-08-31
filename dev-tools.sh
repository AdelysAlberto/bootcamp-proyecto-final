#!/bin/bash

# Development tools script for local development
# Use this when developing outside of Docker

set -e

echo "🔧 Development Tools Manager"
echo ""

case "$1" in
    "setup")
        echo "📦 Setting up development environment..."
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
        echo "✅ Dependencies installed"

        echo "🪝 Installing pre-commit hooks..."
        pre-commit install
        echo "✅ Pre-commit hooks installed"
        ;;

    "lint")
        echo "🔍 Running linting checks..."
        echo "📝 Running ruff..."
        ruff check .
        echo "🎨 Running black..."
        black --check .
        echo "🔬 Running mypy..."
        mypy .
        echo "✅ All linting checks passed"
        ;;

    "format")
        echo "🎨 Formatting code..."
        echo "📝 Running ruff fixes..."
        ruff check --fix .
        echo "🎨 Running black..."
        black .
        echo "✅ Code formatted"
        ;;

    "type-check")
        echo "🔬 Running type checks..."
        mypy .
        echo "✅ Type checks passed"
        ;;

    "pre-commit")
        echo "🪝 Running pre-commit on all files..."
        pre-commit run --all-files
        echo "✅ Pre-commit checks completed"
        ;;

    "test")
        echo "🧪 Running tests..."
        # Add test command here when tests are implemented
        echo "⚠️  No tests implemented yet"
        ;;

    "check-all")
        echo "🔍 Running all checks..."
        echo "1. 📝 Linting..."
        ruff check .
        echo "2. 🎨 Format checking..."
        black --check .
        echo "3. 🔬 Type checking..."
        mypy .
        echo "4. 🪝 Pre-commit..."
        pre-commit run --all-files
        echo "✅ All checks passed!"
        ;;

    "clean")
        echo "🧹 Cleaning up..."
        find . -type f -name "*.pyc" -delete
        find . -type d -name "__pycache__" -delete
        find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
        find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
        echo "✅ Cleanup completed"
        ;;

    *)
        echo "Usage: $0 {setup|lint|format|type-check|pre-commit|test|check-all|clean}"
        echo ""
        echo "Commands:"
        echo "  setup       - Install dependencies and setup pre-commit"
        echo "  lint        - Run all linting checks"
        echo "  format      - Format code with black and ruff"
        echo "  type-check  - Run mypy type checking"
        echo "  pre-commit  - Run pre-commit hooks"
        echo "  test        - Run tests"
        echo "  check-all   - Run all checks"
        echo "  clean       - Clean up cache files"
        exit 1
        ;;
esac
