# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MACSet is a MAC address set processor designed for OpenWrt systems. It monitors source files containing MAC addresses with comments, automatically processes changes, and generates clean output files containing only valid MAC addresses. MACSet supports multiple operation modes including directory monitoring and individual file pairs.

## Key Architecture Components

### Core Scripts
- `macset-processor.sh`: Main processing script that handles MAC address validation, file monitoring, and processing
- `macset`: OpenWrt init.d service script using procd for service management
- `install.sh`: Installation script that sets up the service with proper permissions and directories

### Configuration System
- `config`: Main configuration file with extensive options including operation modes, monitoring intervals, and file validation settings
- Two operation modes: "directory" (monitors SOURCE_DIR with FILE_PATTERN) and "pairs" (processes individual FILE_PAIRS)
- Supports three-column file pairs format: source|destination|command (optional command executed after processing)

### Directory Structure
```
/etc/macset/
├── sources/         # Directory mode: source files with MAC addresses and comments
├── outputs/         # Directory mode: processed clean MAC address files  
└── config           # Configuration file

/var/log/macset/
└── macset.log       # Service logs

/usr/bin/
└── macset-processor # Main processing script

/etc/init.d/
└── macset           # OpenWrt service script
```

## Development Commands

### Installation and Service Management
```bash
# Install using Makefile (preferred)
make install

# Install using script
sudo ./install.sh

# Test installation compatibility
./test_openwrt_compatibility.sh

# Service management
/etc/init.d/macset start|stop|restart|status
/etc/init.d/macset config        # Show configuration
/etc/init.d/macset process       # Process files once
```

### Testing and Development
```bash
# Run syntax and functionality tests
make test

# Test three-column file pairs feature
./test_three_column_file_pairs.sh

# Test OpenWrt fallback methods
./test_openwrt_fallback.sh

# Manual processing examples
./macset-processor.sh -p /path/to/sources /path/to/outputs
./macset-processor.sh -m -F "/etc/network.txt|/var/output.txt|command"
```

### Build and Package
```bash
# Create distribution package
make package

# Clean build artifacts  
make clean

# Show installation status
make status
```

## File Processing Logic

### MAC Address Validation
The processor validates MAC addresses using regex pattern: `^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$`
- Supports both colon (:) and dash (-) separators
- Removes comments (lines starting with #) and inline comments
- Filters out invalid entries and logs warnings

### File Change Detection
- Uses `stat` command when available for modification time tracking
- Falls back to file size + first line hash method for OpenWrt compatibility
- Stores tracking data in `/tmp/macset_last_modified`

### Operation Modes
1. **Directory Mode**: Monitors SOURCE_DIR with FILE_PATTERN, generates files with "_clean.txt" suffix
2. **File Pairs Mode**: Processes individual source|destination|command triplets, supports custom commands

## Configuration Options

Key configuration variables in `/etc/macset/config`:
- `OPERATION_MODE`: "directory" or "pairs"
- `FILE_PAIRS`: Comma-separated source|dest|command pairs
- `SOURCE_DIR`/`OUTPUT_DIR`: Directory mode paths
- `FILE_PATTERN`: Glob pattern for directory mode
- `MONITOR_INTERVAL`: File check frequency in seconds
- `DEBUG`: Enable detailed logging

## OpenWrt Compatibility Features

- Uses standard POSIX shell scripting for broad compatibility
- Automatic detection and installation of `coreutils-stat` if available
- Fallback file change detection when `stat` unavailable  
- Uses `procd` for proper OpenWrt service management
- Minimal dependency requirements (grep, sed, find)

## Testing and Validation

The project includes comprehensive test scripts:
- `test_openwrt_compatibility.sh`: Validates OpenWrt system compatibility
- `test_openwrt_fallback.sh`: Tests fallback methods when tools missing
- `test_three_column_file_pairs.sh`: Tests advanced file pairs with commands
- `make test`: Runs syntax validation and basic processing tests