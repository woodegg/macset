#!/bin/bash
#
# Test script for MACSet Processor three-column file pairs functionality
# 
# This script tests the new three-column format where the third column
# is an optional command to execute after file processing.
#
# Author: Jun Zhang
# Version: 1.4.0
# License: MIT
# Date: 2025-07-22

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="/tmp/macset_test_$$"
SCRIPT_PATH="./macset-processor.sh"
LOG_FILE="$TEST_DIR/test.log"

# Create a temporary config file for testing
TEMP_CONFIG="$TEST_DIR/test_config"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment in $TEST_DIR"
    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_DIR/sources"
    mkdir -p "$TEST_DIR/outputs"
    mkdir -p "$TEST_DIR/logs"
    
    # Create a temporary config file to avoid permission issues
    cat > "$TEMP_CONFIG" << EOF
# Temporary test configuration
SOURCE_DIR="$TEST_DIR/sources"
OUTPUT_DIR="$TEST_DIR/outputs"
LOG_FILE="$TEST_DIR/logs/macset.log"
MONITOR_INTERVAL=1
DEBUG=1
FILE_PATTERN="*.txt"
OPERATION_MODE="pairs"
EOF
    
    # Create test source files
    cat > "$TEST_DIR/sources/network.txt" << EOF
# Network devices MAC addresses
aa:bb:cc:dd:ee:01  # Router
aa:bb:cc:dd:ee:02  # Switch
aa:bb:cc:dd:ee:03  # Access Point
invalid_mac_address  # This should be ignored
EOF

    cat > "$TEST_DIR/sources/guest.txt" << EOF
# Guest devices
ff:ee:dd:cc:bb:01  # Guest laptop
ff:ee:dd:cc:bb:02  # Guest phone
ff:ee:dd:cc:bb:03  # Guest tablet
EOF

    cat > "$TEST_DIR/sources/iot.txt" << EOF
# IoT devices
11:22:33:44:55:01  # Smart bulb
11:22:33:44:55:02  # Smart plug
11:22:33:44:55:03  # Smart camera
EOF

    # Create a mock command script
    cat > "$TEST_DIR/mock_command.sh" << 'EOF'
#!/bin/bash
echo "Mock command executed at $(date)" >> /tmp/macset_test_command.log
echo "Command arguments: $@" >> /tmp/macset_test_command.log
exit 0
EOF
    chmod +x "$TEST_DIR/mock_command.sh"
    
    # Create a mock command that fails
    cat > "$TEST_DIR/mock_fail_command.sh" << 'EOF'
#!/bin/bash
echo "Mock fail command executed at $(date)" >> /tmp/macset_test_command.log
echo "This command is supposed to fail" >> /tmp/macset_test_command.log
exit 1
EOF
    chmod +x "$TEST_DIR/mock_fail_command.sh"
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Cleaning up test environment"
    rm -rf "$TEST_DIR"
    rm -f /tmp/macset_test_command.log
}

# Test function: Two-column format (backward compatibility)
test_two_column_format() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing two-column format (backward compatibility)"
    
    local file_pairs="$TEST_DIR/sources/network.txt|$TEST_DIR/outputs/network_clean.txt"
    
    if ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -p -F "$file_pairs" > "$LOG_FILE" 2>&1; then
        if [ -f "$TEST_DIR/outputs/network_clean.txt" ]; then
            local line_count=$(wc -l < "$TEST_DIR/outputs/network_clean.txt")
            if [ "$line_count" -eq 3 ]; then
                log_pass "Two-column format works correctly"
            else
                log_fail "Two-column format: Expected 3 lines, got $line_count"
            fi
        else
            log_fail "Two-column format: Output file not created"
        fi
    else
        log_fail "Two-column format: Command failed"
    fi
}

# Test function: Three-column format with command
test_three_column_format_with_command() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing three-column format with command"
    
    local file_pairs="$TEST_DIR/sources/guest.txt|$TEST_DIR/outputs/guest_clean.txt|$TEST_DIR/mock_command.sh"
    
    if ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -p -F "$file_pairs" > "$LOG_FILE" 2>&1; then
        if [ -f "$TEST_DIR/outputs/guest_clean.txt" ]; then
            local line_count=$(wc -l < "$TEST_DIR/outputs/guest_clean.txt")
            if [ "$line_count" -eq 3 ]; then
                if [ -f "/tmp/macset_test_command.log" ]; then
                    log_pass "Three-column format with command works correctly"
                else
                    log_fail "Three-column format: Command log not created"
                fi
            else
                log_fail "Three-column format: Expected 3 lines, got $line_count"
            fi
        else
            log_fail "Three-column format: Output file not created"
        fi
    else
        log_fail "Three-column format: Command failed"
    fi
}

# Test function: Three-column format with failing command
test_three_column_format_with_failing_command() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing three-column format with failing command"
    
    local file_pairs="$TEST_DIR/sources/iot.txt|$TEST_DIR/outputs/iot_clean.txt|$TEST_DIR/mock_fail_command.sh"
    
    if ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -p -F "$file_pairs" > "$LOG_FILE" 2>&1; then
        if [ -f "$TEST_DIR/outputs/iot_clean.txt" ]; then
            local line_count=$(wc -l < "$TEST_DIR/outputs/iot_clean.txt")
            if [ "$line_count" -eq 3 ]; then
                # Check if error was logged
                if grep -q "Command failed" "$LOG_FILE"; then
                    log_pass "Three-column format with failing command handled correctly"
                else
                    log_fail "Three-column format: Failed command error not logged"
                fi
            else
                log_fail "Three-column format: Expected 3 lines, got $line_count"
            fi
        else
            log_fail "Three-column format: Output file not created"
        fi
    else
        log_fail "Three-column format: Command failed"
    fi
}

# Test function: Mixed format (some with commands, some without)
test_mixed_format() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing mixed format (some with commands, some without)"
    
    local file_pairs="$TEST_DIR/sources/network.txt|$TEST_DIR/outputs/network_clean.txt,$TEST_DIR/sources/guest.txt|$TEST_DIR/outputs/guest_clean.txt|$TEST_DIR/mock_command.sh"
    
    if ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -p -F "$file_pairs" > "$LOG_FILE" 2>&1; then
        local network_lines=$(wc -l < "$TEST_DIR/outputs/network_clean.txt" 2>/dev/null || echo "0")
        local guest_lines=$(wc -l < "$TEST_DIR/outputs/guest_clean.txt" 2>/dev/null || echo "0")
        
        if [ "$network_lines" -eq 3 ] && [ "$guest_lines" -eq 3 ]; then
            log_pass "Mixed format works correctly"
        else
            log_fail "Mixed format: Expected 3 lines each, got network=$network_lines, guest=$guest_lines"
        fi
    else
        log_fail "Mixed format: Command failed"
    fi
}

# Test function: Complex command with arguments
test_complex_command() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing complex command with arguments"
    
    local file_pairs="$TEST_DIR/sources/network.txt|$TEST_DIR/outputs/network_clean.txt|echo 'Complex command executed' >> /tmp/macset_test_command.log && echo 'With multiple arguments' >> /tmp/macset_test_command.log"
    
    if ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -p -F "$file_pairs" > "$LOG_FILE" 2>&1; then
        if [ -f "$TEST_DIR/outputs/network_clean.txt" ]; then
            local line_count=$(wc -l < "$TEST_DIR/outputs/network_clean.txt")
            if [ "$line_count" -eq 3 ]; then
                if grep -q "Complex command executed" /tmp/macset_test_command.log && grep -q "With multiple arguments" /tmp/macset_test_command.log; then
                    log_pass "Complex command with arguments works correctly"
                else
                    log_fail "Complex command: Expected log entries not found"
                fi
            else
                log_fail "Complex command: Expected 3 lines, got $line_count"
            fi
        else
            log_fail "Complex command: Output file not created"
        fi
    else
        log_fail "Complex command: Command failed"
    fi
}

# Test function: Empty command (should be ignored)
test_empty_command() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing empty command (should be ignored)"
    
    local file_pairs="$TEST_DIR/sources/guest.txt|$TEST_DIR/outputs/guest_clean.txt|"
    
    if ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -p -F "$file_pairs" > "$LOG_FILE" 2>&1; then
        if [ -f "$TEST_DIR/outputs/guest_clean.txt" ]; then
            local line_count=$(wc -l < "$TEST_DIR/outputs/guest_clean.txt")
            if [ "$line_count" -eq 3 ]; then
                log_pass "Empty command handled correctly (ignored)"
            else
                log_fail "Empty command: Expected 3 lines, got $line_count"
            fi
        else
            log_fail "Empty command: Output file not created"
        fi
    else
        log_fail "Empty command: Command failed"
    fi
}

# Test function: Monitor mode with commands
test_monitor_mode_with_commands() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "Testing monitor mode with commands (timeout after 3 seconds)"
    
    local file_pairs="$TEST_DIR/sources/network.txt|$TEST_DIR/outputs/network_monitor_clean.txt|$TEST_DIR/mock_command.sh"
    
    # Start monitor in background
    ./run_test.sh "$TEMP_CONFIG" "$TEST_DIR/macset.pid" -m -i 1 -F "$file_pairs" > "$LOG_FILE" 2>&1 &
    local monitor_pid=$!
    
    # Wait a bit for initial processing
    sleep 2
    
    # Modify source file to trigger change
    echo "aa:bb:cc:dd:ee:04  # New device" >> "$TEST_DIR/sources/network.txt"
    
    # Wait for processing
    sleep 2
    
    # Kill monitor process
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    
    if [ -f "$TEST_DIR/outputs/network_monitor_clean.txt" ]; then
        local line_count=$(wc -l < "$TEST_DIR/outputs/network_monitor_clean.txt")
        if [ "$line_count" -eq 4 ]; then
            log_pass "Monitor mode with commands works correctly"
        else
            log_fail "Monitor mode: Expected 4 lines, got $line_count"
        fi
    else
        log_fail "Monitor mode: Output file not created"
    fi
}

# Main test execution
main() {
    echo "=== MACSet Processor Three-Column File Pairs Test Suite ==="
    echo "Testing version: $(grep 'Version:' "$SCRIPT_PATH" | head -1 | cut -d' ' -f2)"
    echo
    
    # Check if script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}Error: Script not found at $SCRIPT_PATH${NC}"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$SCRIPT_PATH"
    
    # Setup test environment
    setup_test_env
    
    # Run tests
    test_two_column_format
    test_three_column_format_with_command
    test_three_column_format_with_failing_command
    test_mixed_format
    test_complex_command
    test_empty_command
    test_monitor_mode_with_commands
    
    # Print results
    echo
    echo "=== Test Results ==="
    echo "Total tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Cleanup on exit
trap cleanup_test_env EXIT

# Run main function
main "$@" 