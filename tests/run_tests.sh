#!/usr/bin/env zsh
# Trove Test Runner
# Runs all test suites with zunit

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "${BLUE}╔════════════════════════════════════════╗${NC}"
echo "${BLUE}║     Trove Test Suite with zunit       ║${NC}"
echo "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if zunit is installed
if ! command -v zunit &> /dev/null; then
  echo "${RED}✗ Error: zunit is not installed${NC}"
  echo ""
  echo "Install with:"
  echo "  brew install zunit-zsh/zunit/zunit"
  exit 1
fi

echo "${GREEN}✓ zunit $(zunit --version) found${NC}"
echo ""

# Count test files
TEST_FILES=("${TEST_DIR}"/test_*.zunit)
TEST_COUNT=${#TEST_FILES[@]}

echo "${BLUE}Running ${TEST_COUNT} test suites...${NC}"
echo ""

# Run each test suite
FAILED=0
PASSED=0
TOTAL_TESTS=0
TOTAL_PASSED=0

for test_file in "${TEST_FILES[@]}"; do
  test_name=$(basename "${test_file}" .zunit)
  echo "${YELLOW}▶ ${test_name}${NC}"

  # Capture output and parse results
  output=$(zunit "${test_file}" 2>&1)
  exit_code=$?

  echo "$output"

  if [ $exit_code -eq 0 ]; then
    ((PASSED++))
  else
    ((FAILED++))
  fi

  # Extract test counts from output
  suite_total=$(echo "$output" | grep "tests run in" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
  suite_passed=$(echo "$output" | grep "Passed" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $2}')

  if [[ -n "$suite_total" ]]; then
    ((TOTAL_TESTS += suite_total))
  fi
  if [[ -n "$suite_passed" ]]; then
    ((TOTAL_PASSED += suite_passed))
  fi

  echo ""
done

# Summary
echo "${BLUE}╔════════════════════════════════════════╗${NC}"
echo "${BLUE}║           Test Summary                 ║${NC}"
echo "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Test suites run: ${TEST_COUNT}"
echo "Suites passed:   ${PASSED}"
echo "Suites failed:   ${FAILED}"
echo ""
echo "Total tests:     ${TOTAL_TESTS}"
echo "${GREEN}Tests passed:    ${TOTAL_PASSED}${NC}"
if [ $((TOTAL_TESTS - TOTAL_PASSED)) -gt 0 ]; then
  echo "${RED}Tests failed:    $((TOTAL_TESTS - TOTAL_PASSED))${NC}"
fi
echo ""

if [ ${FAILED} -gt 0 ]; then
  echo "${RED}✗ Some test suites failed${NC}"
  exit 1
else
  echo "${GREEN}✓ All tests passed!${NC}"
  exit 0
fi
