#!/bin/sh
#
# MACSet Installation Script
# 
# This script installs the MACSet MAC Address Processor on OpenWrt systems.
# It copies all necessary files to their proper locations and sets up the service.
# Supports multiple files and directories.
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

# Installation paths
INSTALL_DIR="/usr/bin"
INIT_DIR="/etc/init.d"
CONFIG_DIR="/etc/macset"
SOURCE_DIR="/etc/macset/sources"
OUTPUT_DIR="/etc/macset/outputs"
LOG_DIR="/var/log/macset"

# Script name
SCRIPT_NAME="macset-processor.sh"
INIT_SCRIPT="macset"
CONFIG_FILE="config"

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

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_status "ERROR" "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check OpenWrt system
check_openwrt() {
    if [ ! -f "/etc/openwrt_release" ] && [ ! -f "/etc/config/system" ]; then
        print_status "WARN" "This doesn't appear to be an OpenWrt system"
        print_status "WARN" "Installation may not work correctly"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check dependencies
check_dependencies() {
    print_status "STEP" "Checking dependencies..."
    
    local missing_deps=""
    
    # Check for required commands
    for cmd in grep sed stat find; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps="$missing_deps $cmd"
        fi
    done
    
    if [ -n "$missing_deps" ]; then
        print_status "ERROR" "Missing required dependencies:$missing_deps"
        print_status "ERROR" "Please install the missing packages and try again"
        exit 1
    fi
    
    print_status "INFO" "All dependencies are available"
}

# Function to create directories
create_directories() {
    print_status "STEP" "Creating directories..."
    
    for dir in "$CONFIG_DIR" "$SOURCE_DIR" "$OUTPUT_DIR" "$LOG_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "INFO" "Created directory: $dir"
        else
            print_status "INFO" "Directory already exists: $dir"
        fi
    done
}

# Function to copy files
copy_files() {
    print_status "STEP" "Copying files..."
    
    # Copy main script
    if [ -f "$SCRIPT_NAME" ]; then
        cp "$SCRIPT_NAME" "$INSTALL_DIR/macset-processor"
        chmod +x "$INSTALL_DIR/macset-processor"
        print_status "INFO" "Installed main script: $INSTALL_DIR/macset-processor"
    else
        print_status "ERROR" "Main script not found: $SCRIPT_NAME"
        exit 1
    fi
    
    # Copy init script
    if [ -f "$INIT_SCRIPT" ]; then
        cp "$INIT_SCRIPT" "$INIT_DIR/macset"
        chmod +x "$INIT_DIR/macset"
        print_status "INFO" "Installed init script: $INIT_DIR/macset"
    else
        print_status "ERROR" "Init script not found: $INIT_SCRIPT"
        exit 1
    fi
    
    # Copy config file if it doesn't exist
    if [ -f "$CONFIG_FILE" ] && [ ! -f "$CONFIG_DIR/config" ]; then
        cp "$CONFIG_FILE" "$CONFIG_DIR/config"
        print_status "INFO" "Installed config file: $CONFIG_DIR/config"
    elif [ -f "$CONFIG_FILE" ]; then
        print_status "WARN" "Config file already exists, skipping: $CONFIG_DIR/config"
    fi
    
    # Copy sample source files
    if [ -d "sources" ]; then
        print_status "INFO" "Copying sample source files..."
        cp -r sources/* "$SOURCE_DIR/" 2>/dev/null || true
        print_status "INFO" "Sample source files copied to: $SOURCE_DIR"
    fi
}

# Function to set permissions
set_permissions() {
    print_status "STEP" "Setting permissions..."
    
    # Set directory permissions
    chmod 755 "$CONFIG_DIR" "$SOURCE_DIR" "$OUTPUT_DIR" "$LOG_DIR"
    
    # Set file permissions
    chmod 644 "$CONFIG_DIR/config" 2>/dev/null || true
    chmod 644 "$SOURCE_DIR"/*.txt 2>/dev/null || true
    
    print_status "INFO" "Permissions set correctly"
}

# Function to enable service
enable_service() {
    print_status "STEP" "Enabling service..."
    
    if [ -x "$INIT_DIR/macset" ]; then
        "$INIT_DIR/macset" enable
        print_status "INFO" "Service enabled for auto-start"
    else
        print_status "ERROR" "Failed to enable service"
        exit 1
    fi
}

# Function to start service
start_service() {
    print_status "STEP" "Starting service..."
    
    if [ -x "$INIT_DIR/macset" ]; then
        "$INIT_DIR/macset" start
        if [ $? -eq 0 ]; then
            print_status "INFO" "Service started successfully"
        else
            print_status "WARN" "Service failed to start, check logs for details"
        fi
    else
        print_status "ERROR" "Failed to start service"
        exit 1
    fi
}

# Function to show installation summary
show_summary() {
    print_status "STEP" "Installation Summary"
    echo "=================================="
    echo "Files installed:"
    echo "  - Main script: $INSTALL_DIR/macset-processor"
    echo "  - Init script: $INIT_DIR/macset"
    echo "  - Config file: $CONFIG_DIR/config"
    echo ""
    echo "Directories created:"
    echo "  - Config: $CONFIG_DIR"
    echo "  - Sources: $SOURCE_DIR"
    echo "  - Outputs: $OUTPUT_DIR"
    echo "  - Logs: $LOG_DIR"
    echo ""
    echo "Service management:"
    echo "  - Start: $INIT_DIR/macset start"
    echo "  - Stop: $INIT_DIR/macset stop"
    echo "  - Status: $INIT_DIR/macset status"
    echo "  - Restart: $INIT_DIR/macset restart"
    echo "  - Sources: $INIT_DIR/macset sources"
    echo "  - Outputs: $INIT_DIR/macset outputs"
    echo "  - Process: $INIT_DIR/macset process"
    echo ""
    echo "Configuration:"
    echo "  - Edit: $CONFIG_DIR/config"
    echo "  - Source files: $SOURCE_DIR/*.txt"
    echo "  - Output files: $OUTPUT_DIR/*_clean.txt"
    echo "  - Log file: $LOG_DIR/macset.log"
    echo ""
    print_status "INFO" "Installation completed successfully!"
}

# Function to show uninstall instructions
show_uninstall() {
    echo ""
    print_status "INFO" "To uninstall MACSet, run:"
    echo "  $INIT_DIR/macset stop"
    echo "  $INIT_DIR/macset disable"
    echo "  rm -f $INSTALL_DIR/macset-processor"
    echo "  rm -f $INIT_DIR/macset"
    echo "  rm -rf $CONFIG_DIR"
    echo "  rm -rf $LOG_DIR"
}

# Function to show usage examples
show_examples() {
    echo ""
    print_status "INFO" "Usage Examples:"
    echo "=================="
    echo ""
    echo "1. Check service status:"
    echo "   $INIT_DIR/macset status"
    echo ""
    echo "2. List source files:"
    echo "   $INIT_DIR/macset sources"
    echo ""
    echo "3. List output files:"
    echo "   $INIT_DIR/macset outputs"
    echo ""
    echo "4. Process all files once:"
    echo "   $INIT_DIR/macset process"
    echo ""
    echo "5. Add a new source file:"
    echo "   echo '00:11:22:33:44:55 # New Device' > $SOURCE_DIR/new_devices.txt"
    echo ""
    echo "6. View configuration:"
    echo "   $INIT_DIR/macset config"
    echo ""
    echo "7. Manual processing:"
    echo "   macset-processor -p /path/to/sources /path/to/outputs"
    echo ""
    echo "8. Monitor with custom pattern:"
    echo "   macset-processor -m -f '*.mac' /path/to/sources /path/to/outputs"
}

# Main installation function
main() {
    echo "MACSet Installation Script v1.3.0"
    echo "=================================="
    echo ""
    
    # Check prerequisites
    check_root
    check_openwrt
    check_dependencies
    
    # Perform installation
    create_directories
    copy_files
    set_permissions
    enable_service
    start_service
    
    # Show results
    show_summary
    show_examples
    show_uninstall
}

# Run main function
main "$@" 