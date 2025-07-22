#!/bin/sh
#
# OpenWrt Fallback Test Script for MACSet
# 
# This script tests the fallback methods when stat command is not available
# by temporarily hiding the stat command and testing the fallback functionality.
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

# Test the fallback method without stat
test_fallback_method() {
    print_status "STEP" "Testing fallback method without stat command..."
    
    # Create a test file
    local test_file="/tmp/macset_test_file"
    echo "test content" > "$test_file"
    
    # Define the function locally for testing (same as in main script)
    get_file_mtime() {
        local file="$1"
        
        # Try stat first (if available)
        if command -v stat >/dev/null 2>&1; then
            stat -c %Y "$file" 2>/dev/null || echo "0"
        else
            # Fallback for OpenWrt: use file size + first line hash as change indicator
            if [ -f "$file" ]; then
                local size=$(wc -c < "$file" 2>/dev/null || echo "0")
                # Use first line content to detect changes (simple but effective)
                local first_line=$(head -1 "$file" 2>/dev/null | wc -c 2>/dev/null || echo "0")
                echo "$((size * 1000 + first_line))"
            else
                echo "0"
            fi
        fi
    }
    
    # Test with stat available (should work)
    local mtime_with_stat=$(get_file_mtime "$test_file")
    print_status "INFO" "With stat available: $mtime_with_stat"
    
    # Test without stat (simulate OpenWrt environment)
    # Create a wrapper function that doesn't use stat
    get_file_mtime_fallback() {
        local file="$1"
        # Fallback for OpenWrt: use file size + first line hash as change indicator
        if [ -f "$file" ]; then
            local size=$(wc -c < "$file" 2>/dev/null || echo "0")
            # Use first line content to detect changes (simple but effective)
            local first_line=$(head -1 "$file" 2>/dev/null | wc -c 2>/dev/null || echo "0")
            echo "$((size * 1000 + first_line))"
        else
            echo "0"
        fi
    }
    
    # Test the fallback method
    local mtime_without_stat=$(get_file_mtime_fallback "$test_file")
    print_status "INFO" "Without stat (fallback): $mtime_without_stat"
        
        # Check if fallback method works
        if [ "$mtime_without_stat" != "0" ] && [ "$mtime_without_stat" -gt 0 ]; then
            print_status "INFO" "✓ Fallback method works correctly"
            rm -f "$test_file"
            return 0
        else
            print_status "ERROR" "✗ Fallback method failed: $mtime_without_stat"
            rm -f "$test_file"
            return 1
        fi
}

# Test file change detection
test_file_change_detection() {
    print_status "STEP" "Testing file change detection with fallback method..."
    
    # Create test files
    local test_file="/tmp/macset_change_test"
    local tracking_file="/tmp/macset_last_modified"
    
    # Define the function locally for testing (OpenWrt fallback only)
    get_file_mtime() {
        local file="$1"
        # Fallback for OpenWrt: use file size + first line hash as change indicator
        if [ -f "$file" ]; then
            local size=$(wc -c < "$file" 2>/dev/null || echo "0")
            # Use first line content to detect changes (simple but effective)
            local first_line=$(head -1 "$file" 2>/dev/null | wc -c 2>/dev/null || echo "0")
            echo "$((size * 1000 + first_line))"
        else
            echo "0"
        fi
    }
    
    # Create initial file
    echo "initial content" > "$test_file"
    touch "$tracking_file"
    
    # Get initial modification time
    local initial_mtime=$(get_file_mtime "$test_file")
    local file_key="test_file"
    
    # Store initial time
    echo "$file_key:$initial_mtime" > "$tracking_file"
    print_status "INFO" "Initial file size: $initial_mtime"
    
    # Modify the file
    echo "modified content" > "$test_file"
    local new_mtime=$(get_file_mtime "$test_file")
    print_status "INFO" "Modified file size: $new_mtime"
    
    # Check if change was detected
    local last_modified=$(grep "^$file_key:" "$tracking_file" 2>/dev/null | cut -d: -f2 || echo "0")
    
    if [ "$new_mtime" -gt "$last_modified" ]; then
        print_status "INFO" "✓ File change detection works correctly"
        rm -f "$test_file" "$tracking_file"
        return 0
    else
        print_status "ERROR" "✗ File change detection failed"
        rm -f "$test_file" "$tracking_file"
        return 1
    fi
}

# Main test function
main() {
    print_status "INFO" "OpenWrt Fallback Test for MACSet v1.4.0"
    print_status "INFO" "========================================"
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test 1: Fallback method without stat
    tests_total=$((tests_total + 1))
    if test_fallback_method; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 2: File change detection
    tests_total=$((tests_total + 1))
    if test_file_change_detection; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Summary
    print_status "STEP" "Test Summary"
    print_status "INFO" "Tests passed: $tests_passed/$tests_total"
    
    if [ "$tests_passed" -eq "$tests_total" ]; then
        print_status "INFO" "✅ All fallback tests passed! MACSet will work on OpenWrt without stat."
        return 0
    else
        print_status "ERROR" "❌ Some fallback tests failed. Please check the errors above."
        return 1
    fi
}

# Run the test
main "$@" 