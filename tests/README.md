# Trove Test Suite

Comprehensive test suite for Trove v0.1.0-beta using zunit.

## Test Overview

| Test Suite | Tests | Description |
|------------|-------|-------------|
| `test_colors.zunit` | 13 | Color scheme functionality |
| `test_logging.zunit` | 19 | Logging functions and levels |
| `test_helpers.zunit` | 30 | Path, platform, and utility helpers |
| `test_monitoring.zunit` | 15 | System metrics functions |
| `test_date.zunit` | 28 | Date/time utilities |
| `test_integration.zunit` | 29 | Cross-library integration |
| **Total** | **134** | **All tests passing** |

## Running Tests

### Run All Tests

```bash
cd /opt/trove

# Run all test suites
for test in tests/test_*.zunit; do
  echo "=== $(basename $test) ==="
  zunit "$test"
  echo ""
done
```

### Run Individual Test Suite

```bash
cd /opt/trove

# Examples
zunit tests/test_logging.zunit
zunit tests/test_colors.zunit
zunit tests/test_helpers.zunit
```

### Run with Test Runner

```bash
cd /opt/trove
./tests/run_tests.sh
```

## Test Requirements

- **zunit**: Installed via Homebrew
  ```bash
  brew install zunit-zsh/zunit/zunit
  ```

- **Standard tools**: Most tests work with standard macOS/Linux tools
  - Some monitoring tests require `awk` and `sed` in PATH

## Test Coverage

### Logging (`test_logging.zunit`)
- All log levels (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
- Level filtering and hierarchy
- Special output functions (bot, running, action, ok)
- Silent execution and result printing
- Dynamic log level changes

### Colors (`test_colors.zunit`)
- All 5 color schemes (monokai, solarized, nord, dracula, gruvbox)
- Color variable definitions
- Scheme switching
- Invalid scheme handling

### Helpers (`test_helpers.zunit`)
- Path validation (exists, is_directory, is_file)
- Permission checking (readable, writable, executable)
- Platform detection (macOS, Linux, Ubuntu)
- Command detection and requirements
- Environment variable helpers
- String utilities (trim, lowercase, uppercase, starts_with, ends_with)

### Monitoring (`test_monitoring.zunit`)
- Function existence checks for all monitoring functions
- Disk, memory, CPU, network metrics
- System info and process counts

### Date/Time (`test_date.zunit`)
- Function existence checks for all date/time functions
- Timestamp formatting, arithmetic, validation
- Duration calculations
- Timezone handling

### Integration (`test_integration.zunit`)
- klog binary functionality
- Library independence
- Cross-library integration
- Configuration loading
- Documentation and examples

## Test Philosophy

Tests focus on:
1. **Function existence** - Verify all public APIs exist
2. **Basic functionality** - Core operations work correctly
3. **Error handling** - Invalid input handled gracefully
4. **Integration** - Libraries work together properly
5. **Cross-platform** - Tests pass on macOS (primary) and Ubuntu (target)

## Current Status

✅ **All 134 tests passing on macOS**

Next steps:
- Test on Ubuntu VM to verify cross-platform compatibility
- Add integration tests for real homelab scenarios
