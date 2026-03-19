#!/usr/bin/env zsh

echo "Running all Trove tests..."
echo ""

total_tests=0
total_passed=0

for test in tests/test_*.zunit; do
  name=$(basename "$test" .zunit)
  echo "► $name"
  output=$(zunit "$test" 2>&1)
  
  passed=$(echo "$output" | grep "Passed" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $2}')
  if [[ -n "$passed" ]]; then
    echo "  ✓ $passed tests passed"
    ((total_passed += passed))
    
    # Get total from "X tests run"
    run=$(echo "$output" | grep "tests run" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
    if [[ -n "$run" ]]; then
      ((total_tests += run))
    fi
  fi
done

echo ""
echo "=============================="
echo "Total: $total_passed / $total_tests tests passed"

if [ $total_passed -eq $total_tests ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
