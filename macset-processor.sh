#!/bin/sh
#
# MACSet Processor - MAC Address Set Processor for OpenWrt
# 
# This script monitors source files containing MAC addresses and comments,
# automatically processes changes, and generates clean output files with
# only valid MAC addresses. Supports multiple files, directories, and individual file pairs.
#
# Author: Jun Zhang
# Version: 1.4.0
# License: MIT
# Date: 2025-07-22
#

# Default configuration
DEFAULT_SOURCE_DIR="/etc/macset/sources"
DEFAULT_OUTPUT_DIR="/etc/macset/outputs"
DEFAULT_LOG_FILE="/var/log/macset/macset.log"
DEFAULT_MONITOR_INTERVAL=5
DEFAULT_DEBUG=0
DEFAULT_FILE_PATTERN="*.txt"

# Load configuration if available
CONFIG_FILE="/etc/macset/config"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi

# Set defaults if not defined in config
SOURCE_DIR="${SOURCE_DIR:-$DEFAULT_SOURCE_DIR}"
OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
LOG_FILE="${LOG_FILE:-$DEFAULT_LOG_FILE}"
MONITOR_INTERVAL="${MONITOR_INTERVAL:-$DEFAULT_MONITOR_INTERVAL}"
DEBUG="${DEBUG:-$DEFAULT_DEBUG}"
FILE_PATTERN="${FILE_PATTERN:-$DEFAULT_FILE_PATTERN}"

# PID file for service management
PID_FILE="/var/run/macset.pid"

# Colors for output (if supported)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Add color if terminal supports it
    if [ -t 1 ]; then
        case "$level" in
            "ERROR") echo -e "${RED}[$timestamp] ERROR: $message${NC}" ;;
            "WARN")  echo -e "${YELLOW}[$timestamp] WARN: $message${NC}" ;;
            "INFO")  echo -e "${GREEN}[$timestamp] INFO: $message${NC}" ;;
            "DEBUG") 
                if [ "$DEBUG" -eq 1 ]; then
                    echo -e "${BLUE}[$timestamp] DEBUG: $message${NC}"
                fi
                ;;
        esac
    else
        echo "[$timestamp] $level: $message"
    fi
    
    # Write to log file
    echo "[$timestamp] $level: $message" >> "$LOG_FILE"
}

# MAC address validation function
is_valid_mac() {
    local mac="$1"
    # Check if MAC address matches pattern: xx:xx:xx:xx:xx:xx or xx-xx-xx-xx-xx-xx
    echo "$mac" | grep -E '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$' >/dev/null 2>&1
    return $?
}

# Get output filename from source filename
get_output_filename() {
    local source_file="$1"
    local base_name=$(basename "$source_file")
    local name_without_ext="${base_name%.*}"
    echo "${name_without_ext}_clean.txt"
}

# Function to get file modification time (OpenWrt compatible)
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

# Process MAC addresses from source file
process_mac_addresses() {
    local source_file="$1"
    local output_file="$2"
    local temp_file="/tmp/macset_temp_$$"
    local processed_count=0
    local invalid_count=0
    
    log_message "INFO" "Processing MAC addresses from $source_file"
    
    # Check if source file exists
    if [ ! -f "$source_file" ]; then
        log_message "ERROR" "Source file $source_file does not exist"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    local output_dir=$(dirname "$output_file")
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        log_message "INFO" "Created output directory: $output_dir"
    fi
    
    # Process the file: remove comments, trim whitespace, validate MAC addresses
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [ -z "$line" ] || echo "$line" | grep -q '^[[:space:]]*#'; then
            continue
        fi
        
        # Remove inline comments and trim whitespace
        clean_line=$(echo "$line" | sed 's/#.*$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        # Skip if line is empty after cleaning
        if [ -z "$clean_line" ]; then
            continue
        fi
        
        # Check if it's a valid MAC address
        if is_valid_mac "$clean_line"; then
            echo "$clean_line" >> "$temp_file"
            processed_count=$((processed_count + 1))
            log_message "DEBUG" "Valid MAC address found: $clean_line"
        else
            invalid_count=$((invalid_count + 1))
            log_message "WARN" "Invalid MAC address format: $clean_line"
        fi
    done < "$source_file"
    
    # Move temp file to output file
    if [ -f "$temp_file" ]; then
        mv "$temp_file" "$output_file"
        log_message "INFO" "Processed $processed_count valid MAC addresses, $invalid_count invalid entries from $source_file"
        log_message "INFO" "Output file generated: $output_file"
        return 0
    else
        log_message "WARN" "No valid MAC addresses found in $source_file"
        # Create empty output file
        touch "$output_file"
        return 0
    fi
}

# Process all files in source directory
process_all_files() {
    local source_dir="$1"
    local output_dir="$2"
    local pattern="$3"
    local total_processed=0
    local total_files=0
    
    log_message "INFO" "Processing all files in $source_dir with pattern: $pattern"
    
    # Check if source directory exists
    if [ ! -d "$source_dir" ]; then
        log_message "ERROR" "Source directory $source_dir does not exist"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        log_message "INFO" "Created output directory: $output_dir"
    fi
    
    # Find and process all matching files
    find "$source_dir" -maxdepth 1 -name "$pattern" -type f | while read -r source_file; do
        local output_filename=$(get_output_filename "$source_file")
        local output_file="$output_dir/$output_filename"
        
        log_message "INFO" "Processing file: $source_file -> $output_file"
        process_mac_addresses "$source_file" "$output_file"
        total_files=$((total_files + 1))
    done
    
    log_message "INFO" "Completed processing $total_files files"
}

# Process individual file pairs
process_file_pairs() {
    local file_pairs="$1"
    local total_processed=0
    
    log_message "INFO" "Processing individual file pairs"
    
    # Process each file pair
    echo "$file_pairs" | tr ',' '\n' | while IFS='|' read -r source_file output_file; do
        if [ -n "$source_file" ] && [ -n "$output_file" ]; then
            log_message "INFO" "Processing file pair: $source_file -> $output_file"
            process_mac_addresses "$source_file" "$output_file"
            total_processed=$((total_processed + 1))
        fi
    done
    
    log_message "INFO" "Completed processing $total_processed file pairs"
}

# Monitor multiple files for changes
monitor_files() {
    local source_dir="$1"
    local output_dir="$2"
    local pattern="$3"
    local last_modified_file="/tmp/macset_last_modified"
    
    log_message "INFO" "Starting file monitor for $source_dir with pattern: $pattern"
    log_message "INFO" "Output directory: $output_dir"
    log_message "INFO" "Monitor interval: ${MONITOR_INTERVAL}s"
    
    # Create tracking file for modification times
    touch "$last_modified_file"
    
    # Initial processing
    process_all_files "$source_dir" "$output_dir" "$pattern"
    
    # Monitor loop
    while true; do
        local files_changed=0
        
        # Check each file in the source directory
        find "$source_dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | while read -r source_file; do
            local current_modified=$(get_file_mtime "$source_file")
            local file_key=$(echo "$source_file" | sed 's/[^a-zA-Z0-9]/_/g')
            local last_modified=$(grep "^$file_key:" "$last_modified_file" 2>/dev/null | cut -d: -f2 || echo "0")
            
            # If file has been modified, process it
            if [ "$current_modified" -gt "$last_modified" ]; then
                log_message "INFO" "File change detected: $source_file"
                local output_filename=$(get_output_filename "$source_file")
                local output_file="$output_dir/$output_filename"
                process_mac_addresses "$source_file" "$output_file"
                
                # Update modification time
                sed -i "/^$file_key:/d" "$last_modified_file" 2>/dev/null
                echo "$file_key:$current_modified" >> "$last_modified_file"
                files_changed=1
            fi
        done
        
        # Check for new files
        find "$source_dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | while read -r source_file; do
            local file_key=$(echo "$source_file" | sed 's/[^a-zA-Z0-9]/_/g')
            if ! grep -q "^$file_key:" "$last_modified_file" 2>/dev/null; then
                log_message "INFO" "New file detected: $source_file"
                local output_filename=$(get_output_filename "$source_file")
                local output_file="$output_dir/$output_filename"
                process_mac_addresses "$source_file" "$output_file"
                
                local current_modified=$(get_file_mtime "$source_file")
                echo "$file_key:$current_modified" >> "$last_modified_file"
                files_changed=1
            fi
        done
        
        # Sleep before next check
        sleep "$MONITOR_INTERVAL"
    done
}

# Monitor individual file pairs
monitor_file_pairs() {
    local file_pairs="$1"
    local last_modified_file="/tmp/macset_last_modified"
    
    log_message "INFO" "Starting file pair monitor"
    log_message "INFO" "Monitor interval: ${MONITOR_INTERVAL}s"
    
    # Create tracking file for modification times
    touch "$last_modified_file"
    
    # Initial processing
    process_file_pairs "$file_pairs"
    
    # Monitor loop
    while true; do
        local files_changed=0
        
        # Check each file pair
        echo "$file_pairs" | tr ',' '\n' | while IFS='|' read -r source_file output_file; do
            if [ -n "$source_file" ] && [ -n "$output_file" ]; then
                local current_modified=$(get_file_mtime "$source_file")
                local file_key=$(echo "$source_file" | sed 's/[^a-zA-Z0-9]/_/g')
                local last_modified=$(grep "^$file_key:" "$last_modified_file" 2>/dev/null | cut -d: -f2 || echo "0")
                
                # If file has been modified, process it
                if [ "$current_modified" -gt "$last_modified" ]; then
                    log_message "INFO" "File change detected: $source_file"
                    process_mac_addresses "$source_file" "$output_file"
                    
                    # Update modification time
                    sed -i "/^$file_key:/d" "$last_modified_file" 2>/dev/null
                    echo "$file_key:$current_modified" >> "$last_modified_file"
                    files_changed=1
                fi
            fi
        done
        
        # Sleep before next check
        sleep "$MONITOR_INTERVAL"
    done
}

# Signal handler for graceful shutdown
cleanup() {
    log_message "INFO" "Received shutdown signal, cleaning up..."
    [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
    [ -f "/tmp/macset_last_modified" ] && rm -f "/tmp/macset_last_modified"
    exit 0
}

# Show usage information
show_usage() {
    cat << EOF
MACSet Processor v1.4.0 - MAC Address Set Processor for OpenWrt

Usage: $0 [OPTIONS] [SOURCE_DIR] [OUTPUT_DIR]
   or: $0 [OPTIONS] -F FILE_PAIRS

Options:
    -h, --help          Show this help message
    -v, --version       Show version information
    -d, --debug         Enable debug logging
    -m, --monitor       Run in monitoring mode (default)
    -p, --process       Process files once and exit
    -i, --interval SEC  Set monitor interval in seconds (default: $DEFAULT_MONITOR_INTERVAL)
    -f, --pattern PAT   Set file pattern to monitor (default: $DEFAULT_FILE_PATTERN)
    -s, --single FILE   Process a single file (legacy mode)
    -F, --file-pairs    Specify individual file pairs (format: "src1|dest1,src2|dest2")

Arguments:
    SOURCE_DIR          Directory containing source files with MAC addresses
    OUTPUT_DIR          Directory for processed output files

File Pairs Format:
    Use -F option to specify individual source and destination files:
    -F "file1.txt|/path/to/output1.txt,file2.txt|/path/to/output2.txt"

Examples:
    $0                                    # Run with default configuration
    $0 -p /path/to/sources /path/to/outputs  # Process all files once
    $0 -m -i 10 -f "*.mac" sources outputs  # Monitor with 10-second interval
    $0 -s input.txt output.txt             # Legacy single file mode
    $0 -F "/etc/network.txt|/var/output.txt,/etc/guest.txt|/tmp/guest_clean.txt"

Configuration:
    Edit /etc/macset/config to customize default settings.

EOF
}

# Show version information
show_version() {
    cat << EOF
MACSet Processor v1.4.0
MAC Address Set Processor for OpenWrt

Copyright (c) 2024 MACSet Project Team
License: MIT

EOF
}

# Main function
main() {
    local mode="monitor"
    local source_dir=""
    local output_dir=""
    local pattern="$FILE_PATTERN"
    local single_file_mode=0
    local single_source=""
    local single_output=""
    local file_pairs_mode=0
    local file_pairs=""
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                shift
                ;;
            -m|--monitor)
                mode="monitor"
                shift
                ;;
            -p|--process)
                mode="process"
                shift
                ;;
            -i|--interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -f|--pattern)
                pattern="$2"
                shift 2
                ;;
            -s|--single)
                single_file_mode=1
                if [ -n "$2" ] && [ -n "$3" ]; then
                    single_source="$2"
                    single_output="$3"
                    shift 3
                else
                    log_message "ERROR" "Single file mode requires source and output file paths"
                    show_usage
                    exit 1
                fi
                ;;
            -F|--file-pairs)
                file_pairs_mode=1
                file_pairs="$2"
                shift 2
                ;;
            -*)
                log_message "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$source_dir" ]; then
                    source_dir="$1"
                elif [ -z "$output_dir" ]; then
                    output_dir="$1"
                else
                    log_message "ERROR" "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Set default values if not provided
    source_dir="${source_dir:-$SOURCE_DIR}"
    output_dir="${output_dir:-$OUTPUT_DIR}"
    
    # Create log directory if it doesn't exist
    local log_dir=$(dirname "$LOG_FILE")
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi
    
    # Set up signal handlers
    trap cleanup INT TERM
    
    # Write PID file
    echo $$ > "$PID_FILE"
    
    log_message "INFO" "MACSet Processor starting (PID: $$)"
    log_message "INFO" "Debug mode: $([ "$DEBUG" -eq 1 ] && echo "enabled" || echo "disabled")"
    
    # Run in appropriate mode
    if [ "$single_file_mode" -eq 1 ]; then
        # Legacy single file mode
        log_message "INFO" "Single file mode: $single_source -> $single_output"
        process_mac_addresses "$single_source" "$single_output"
    elif [ "$file_pairs_mode" -eq 1 ]; then
        # Individual file pairs mode
        log_message "INFO" "File pairs mode enabled"
        log_message "INFO" "Log file: $LOG_FILE"
        
        case "$mode" in
            "monitor")
                monitor_file_pairs "$file_pairs"
                ;;
            "process")
                process_file_pairs "$file_pairs"
                ;;
            *)
                log_message "ERROR" "Invalid mode: $mode"
                exit 1
                ;;
        esac
    else
        # Multi-file mode
        log_message "INFO" "Source directory: $source_dir"
        log_message "INFO" "Output directory: $output_dir"
        log_message "INFO" "File pattern: $pattern"
        log_message "INFO" "Log file: $LOG_FILE"
        
        case "$mode" in
            "monitor")
                monitor_files "$source_dir" "$output_dir" "$pattern"
                ;;
            "process")
                process_all_files "$source_dir" "$output_dir" "$pattern"
                ;;
            *)
                log_message "ERROR" "Invalid mode: $mode"
                exit 1
                ;;
        esac
    fi
}

# Run main function with all arguments
main "$@" 