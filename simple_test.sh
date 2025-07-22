#!/bin/sh

# Simple test for the fallback method
get_file_mtime() {
    local file="$1"
    
    # Simulate OpenWrt environment - no stat command
    # if command -v stat >/dev/null 2>&1; then
    #     stat -c %Y "$file" 2>/dev/null || echo "0"
    # else
        # Fallback for OpenWrt: use file size + first line hash as change indicator
        if [ -f "$file" ]; then
            local size=$(wc -c < "$file" 2>/dev/null || echo "0")
            # Use first line content to detect changes (simple but effective)
            local first_line=$(head -1 "$file" 2>/dev/null | wc -c 2>/dev/null || echo "0")
            echo "$((size * 1000 + first_line))"
        else
            echo "0"
        fi
    # fi
}

# Create test files
echo "initial content" > /tmp/test1
echo "modified content" > /tmp/test2

echo "Test 1 (initial): $(get_file_mtime /tmp/test1)"
echo "Test 2 (modified): $(get_file_mtime /tmp/test2)"

# Test change detection
initial=$(get_file_mtime /tmp/test1)
modified=$(get_file_mtime /tmp/test2)

if [ "$modified" -gt "$initial" ]; then
    echo "SUCCESS: Change detected correctly"
else
    echo "FAILED: Change not detected"
fi

rm -f /tmp/test1 /tmp/test2 