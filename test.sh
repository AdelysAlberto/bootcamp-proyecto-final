#!/bin/bash

# Test runner script for the Flask application
# Usage: ./test.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
COVERAGE_MIN=85
VERBOSE=false
INTEGRATION=true
UNIT=true
REPORT_FORMAT="term-missing"

# Function to print colored output
print_colored() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Run tests in verbose mode
    -u, --unit-only         Run only unit tests
    -i, --integration-only  Run only integration tests
    -c, --coverage-min N    Set minimum coverage percentage (default: $COVERAGE_MIN)
    -r, --report FORMAT     Coverage report format: term-missing, html, xml (default: $REPORT_FORMAT)
    --no-cov                Run tests without coverage
    --parallel              Run tests in parallel
    --failed-first          Run failed tests first
    --lf                    Run only last failed tests

EXAMPLES:
    $0                      # Run all tests with coverage
    $0 -v                   # Run tests in verbose mode
    $0 -u                   # Run only unit tests
    $0 -i                   # Run only integration tests
    $0 -c 90                # Set minimum coverage to 90%
    $0 -r html              # Generate HTML coverage report
    $0 --no-cov             # Run tests without coverage
    $0 --parallel           # Run tests in parallel
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -u|--unit-only)
            INTEGRATION=false
            shift
            ;;
        -i|--integration-only)
            UNIT=false
            shift
            ;;
        -c|--coverage-min)
            COVERAGE_MIN="$2"
            shift 2
            ;;
        -r|--report)
            REPORT_FORMAT="$2"
            shift 2
            ;;
        --no-cov)
            NO_COVERAGE=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --failed-first)
            FAILED_FIRST=true
            shift
            ;;
        --lf)
            LAST_FAILED=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if virtual environment is activated
if [[ -z "$VIRTUAL_ENV" ]]; then
    print_colored $YELLOW "Warning: Virtual environment not detected. Activating venv..."
    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
        print_colored $GREEN "Virtual environment activated"
    else
        print_colored $RED "Error: venv not found. Please create and activate virtual environment first."
        exit 1
    fi
fi

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    print_colored $RED "Error: pytest not found. Installing test dependencies..."
    pip install -r requirements-dev.txt
fi

# Build pytest command
PYTEST_CMD="pytest"

# Add verbose flag
if [[ "$VERBOSE" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD -v"
fi

# Add parallel execution
if [[ "$PARALLEL" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD -n auto"
fi

# Add failed first option
if [[ "$FAILED_FIRST" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD --failed-first"
fi

# Add last failed option
if [[ "$LAST_FAILED" == true ]]; then
    PYTEST_CMD="$PYTEST_CMD --lf"
fi

# Add coverage options
if [[ "$NO_COVERAGE" != true ]]; then
    PYTEST_CMD="$PYTEST_CMD --cov=app --cov-report=$REPORT_FORMAT --cov-fail-under=$COVERAGE_MIN"

    # Add additional coverage formats
    case $REPORT_FORMAT in
        html)
            PYTEST_CMD="$PYTEST_CMD --cov-report=html:htmlcov"
            ;;
        xml)
            PYTEST_CMD="$PYTEST_CMD --cov-report=xml"
            ;;
    esac
fi

# Add test selection based on markers
if [[ "$UNIT" == true && "$INTEGRATION" == false ]]; then
    PYTEST_CMD="$PYTEST_CMD -m unit"
elif [[ "$INTEGRATION" == true && "$UNIT" == false ]]; then
    PYTEST_CMD="$PYTEST_CMD -m integration"
fi

# Print configuration
print_colored $BLUE "=== Test Configuration ==="
echo "Unit Tests: $UNIT"
echo "Integration Tests: $INTEGRATION"
echo "Coverage Minimum: $COVERAGE_MIN%"
echo "Coverage Report: $REPORT_FORMAT"
echo "Verbose Mode: $VERBOSE"
echo "Command: $PYTEST_CMD"
print_colored $BLUE "=========================="
echo

# Run pre-test checks
print_colored $YELLOW "Running pre-test checks..."

# Check code style with ruff
if command -v ruff &> /dev/null; then
    print_colored $BLUE "Checking code style with ruff..."
    if ! ruff check .; then
        print_colored $RED "Code style check failed. Please fix issues before running tests."
        exit 1
    fi
    print_colored $GREEN "Code style check passed ✓"
fi

# Check type annotations with mypy
if command -v mypy &> /dev/null; then
    print_colored $BLUE "Checking type annotations with mypy..."
    if ! mypy app/; then
        print_colored $YELLOW "Type check warnings found, but continuing with tests..."
    else
        print_colored $GREEN "Type check passed ✓"
    fi
fi

# Run tests
print_colored $BLUE "Running tests..."
echo "Command: $PYTEST_CMD"
echo

if eval $PYTEST_CMD; then
    print_colored $GREEN "✓ All tests passed!"

    # Show coverage report location if HTML was generated
    if [[ "$REPORT_FORMAT" == "html" ]]; then
        print_colored $BLUE "HTML coverage report generated: htmlcov/index.html"
    fi

    exit 0
else
    print_colored $RED "✗ Some tests failed!"
    exit 1
fi
