#!/bin/bash

# Coverage analysis script
# Usage: ./coverage.sh [target_percentage]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_COVERAGE=${1:-85}

print_colored() {
    echo -e "${1}${2}${NC}"
}

print_colored $BLUE "=== Coverage Analysis ==="
echo "Target Coverage: ${TARGET_COVERAGE}%"
echo

# Check if virtual environment is activated
if [[ -z "$VIRTUAL_ENV" ]]; then
    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
        print_colored $GREEN "Virtual environment activated"
    fi
fi

# Run tests with coverage
print_colored $BLUE "Running tests with coverage analysis..."
pytest --cov=app \
       --cov-report=term-missing \
       --cov-report=html:htmlcov \
       --cov-report=xml \
       --cov-fail-under=$TARGET_COVERAGE \
       tests/

# Check exit code
if [ $? -eq 0 ]; then
    print_colored $GREEN "✓ Coverage target of ${TARGET_COVERAGE}% achieved!"
else
    print_colored $RED "✗ Coverage below target of ${TARGET_COVERAGE}%"
fi

# Generate detailed coverage report
print_colored $BLUE "Generating detailed coverage analysis..."

# Show uncovered lines
echo
print_colored $YELLOW "=== Detailed Coverage Report ==="
coverage report --show-missing

# Show coverage by file
echo
print_colored $YELLOW "=== Coverage by Module ==="
coverage report --format=markdown > coverage_report.md
cat coverage_report.md

echo
print_colored $BLUE "HTML report available at: htmlcov/index.html"
print_colored $BLUE "XML report available at: coverage.xml"
print_colored $BLUE "Markdown report saved to: coverage_report.md"
