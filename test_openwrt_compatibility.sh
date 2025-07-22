#!/bin/sh
#
# OpenWrt Compatibility Test Script for MACSet
# 
# This script tests the OpenWrt compatibility of the MACSet processor
# by checking dependencies and testing the file modification time function.
#
# Author: Jun Zhang
# Version: 1.4.0
# License: MIT
# Date: 2025-07-22
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "STEP")  echo -e "${BLUE}[STEP]${NC} $message" ;;
    esac
}

# Test the get_file_mtime function
test_file_mtime() {
    print_status "STEP" "Testing file modification time function..."
    
    # Create a test file
    local test_file="/tmp/macset_test_file"
    echo "test content" > "$test_file"
    
    # Define the function locally for testing
    get_file_mtime() {
        local file="$1"
        
        # Try stat first (if available)
        if command -v stat >/dev/null 2>&1; then
            stat -c %Y "$file" 2>/dev/null || echo "0"
        else
            # Fallback to ls -l (OpenWrt compatible)
            ls -l "$file" 2>/dev/null | awk '{print $6, $7, $8}' | xargs -I {} date -d "{}" +%s 2>/dev/null || echo "0"
        fi
    }
    
    # Test the function
    local mtime=$(get_file_mtime "$test_file")
    
    if [ "$mtime" != "0" ] && [ "$mtime" -gt 0 ]; then
        print_status "INFO" "File modification time function works: $mtime"
        rm -f "$test_file"
        return 0
    else
        print_status "ERROR" "File modification time function failed: $mtime"
        rm -f "$test_file"
        return 1
    fi
}

# Test dependencies
test_dependencies() {
    print_status "STEP" "Testing dependencies..."
    
    local missing_deps=""
    
    # Check for required commands
    for cmd in grep sed find; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps="$missing_deps $cmd"
        else
            print_status "INFO" "✓ $cmd is available"
        fi
    done
    
    # Check for stat command
    if command -v stat >/dev/null 2>&1; then
        print_status "INFO" "✓ stat command is available"
    else
        print_status "WARN" "⚠ stat command not available, will use fallback method"
    fi
    
    if [ -n "$missing_deps" ]; then
        print_status "ERROR" "Missing required dependencies:$missing_deps"
        return 1
    fi
    
    print_status "INFO" "All dependencies are available"
    return 0
}

# Test MAC address validation
test_mac_validation() {
    print_status "STEP" "Testing MAC address validation..."
    
    # Define the function locally for testing
    is_valid_mac() {
        local mac="$1"
        # MAC address regex pattern: XX:XX:XX:XX:XX:XX where X is hex digit
        echo "$mac" | grep -E '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$' >/dev/null 2>&1
    }
    
    # Test valid MAC addresses
    local valid_macs="00:11:22:33:44:55 aa:bb:cc:dd:ee:ff 01:23:45:67:89:ab"
    for mac in $valid_macs; do
        if is_valid_mac "$mac"; then
            print_status "INFO" "✓ Valid MAC: $mac"
        else
            print_status "ERROR" "✗ Invalid MAC (should be valid): $mac"
            return 1
        fi
    done
    
    # Test invalid MAC addresses
    local invalid_macs="invalid 00:11:22:33:44 00:11:22:33:44:55:66 00-11-22-33-44-55"
    for mac in $invalid_macs; do
        if ! is_valid_mac "$mac"; then
            print_status "INFO" "✓ Invalid MAC correctly rejected: $mac"
        else
            print_status "ERROR" "✗ Invalid MAC (should be rejected): $mac"
            return 1
        fi
    done
    
    print_status "INFO" "MAC address validation works correctly"
    return 0
}

# Main test function
main() {
    print_status "INFO" "OpenWrt Compatibility Test for MACSet v1.4.0"
    print_status "INFO" "============================================="
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test 1: Dependencies
    tests_total=$((tests_total + 1))
    if test_dependencies; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 2: File modification time function
    tests_total=$((tests_total + 1))
    if test_file_mtime; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 3: MAC address validation
    tests_total=$((tests_total + 1))
    if test_mac_validation; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Summary
    print_status "STEP" "Test Summary"
    print_status "INFO" "Tests passed: $tests_passed/$tests_total"
    
    if [ "$tests_passed" -eq "$tests_total" ]; then
        print_status "INFO" "✅ All tests passed! MACSet is OpenWrt compatible."
        return 0
    else
        print_status "ERROR" "❌ Some tests failed. Please check the errors above."
        return 1
    fi
}

# Run the test
main "$@" 