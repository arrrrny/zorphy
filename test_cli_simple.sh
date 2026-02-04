#!/bin/bash

# Zorphy CLI Test Suite - Nested Objects
# This script tests all nested Zorphy object scenarios via the CLI

set -e  # Exit on error

echo "=========================================="
echo "Zorphy CLI Test Suite - Nested Objects"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "TEST $TESTS_RUN: $test_name"
    echo "Command: $test_command"

    if eval "$testcommand"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Clean up function
cleanup() {
    echo "Cleaning up test files..."
    rm -rf test_entities
    rm -f test_*.dart
    echo ""
}

# Trap to ensure cleanup runs
trap cleanup EXIT

# Create test directory
echo "Setting up test environment..."
mkdir -p test_entities
cd zorphy  # Change to zorphy directory
echo ""

# =============================================================================
# TEST 1: Single Nested Zorphy Object
# =============================================================================
echo "=========================================="
echo "TEST GROUP 1: Single Nested Objects"
echo "=========================================="
echo ""

run_test "Create entity with nested Zorphy object" \
    "dart run zorphy:zorphy_cli create -n TestUser -o ../test_entities --field id:String --field name:String --field address:'\$TestAddress' --no-fields"

run_test "Create the nested Address entity" \
    "dart run zorphy:zorphy_cli create -n TestAddress -o ../test_entities --field street:String --field city:String --field country:String --no-fields"

run_test "Verify TestUser file exists" \
    "test -f ../test_entities/testuser.dart"

run_test "Verify TestAddress file exists" \
    "test -f ../test_entities/testaddress.dart"

run_test "Check TestUser contains nested Address type" \
    "grep -q '\$Address get address' ../test_entities/testuser.dart"

echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests Run: $TESTS_RUN"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}SOME TESTS FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
