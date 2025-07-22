# MACSet - MAC Address Set Processor for OpenWrt

## Overview

MACSet is a lightweight, efficient MAC address processing service designed specifically for OpenWrt systems. It monitors source directories or individual file pairs containing MAC addresses and comments, automatically processes changes, and generates clean output files with only valid MAC addresses. **Supports multiple files, directories, and individual file pairs!**

## Features

- **Multi-File Support**: Monitor and process multiple source files simultaneously
- **Individual File Pairs**: Specify source and destination files in different locations
- **Real-time File Monitoring**: Automatically detects changes to any source file
- **Comment Processing**: Removes all comments (lines starting with #) and whitespace
- **MAC Address Validation**: Ensures only valid MAC addresses are included in output
- **OpenWrt Integration**: Native OpenWrt init.d service with proper startup/shutdown
- **OpenWrt Compatibility**: Works on OpenWrt systems without requiring additional packages
- **Resource Efficient**: Lightweight implementation suitable for embedded systems
- **Logging**: Comprehensive logging for debugging and monitoring
- **Flexible Configuration**: Customizable file patterns, directories, and processing options

## Installation

### Prerequisites
- OpenWrt system
- `grep`, `sed`, and `find` commands (usually pre-installed)
- `stat` command (optional - will use fallback method if not available)

### Quick Installation

1. **Clone or download** the MACSet project to your OpenWrt system
2. **Run the installation script** as root:
   ```bash
   sudo ./install.sh
   ```
3. **Verify installation**:
   ```bash
   /etc/init.d/macset status
   ```

### OpenWrt Compatibility

MACSet is designed to work on OpenWrt systems without requiring additional packages. The installation script will:

- Automatically detect if `stat` command is available
- Install `coreutils-stat` package if available and needed
- Use fallback methods for file modification time detection if `stat` is not available
- Test compatibility before installation

To test OpenWrt compatibility:
```bash
./test_openwrt_compatibility.sh
```

### Manual Installation

1. Copy the files to your OpenWrt system:
   ```bash
   # Copy the main script
   cp macset-processor.sh /usr/bin/macset-processor
   chmod +x /usr/bin/macset-processor
   
   # Copy the init script
   cp macset /etc/init.d/macset
   chmod +x /etc/init.d/macset
   
   # Create directories
   mkdir -p /etc/macset/sources /etc/macset/outputs /var/log/macset
   ```

2. Configure the service:
   ```bash
   # Enable the service to start on boot
   /etc/init.d/macset enable
   
   # Start the service
   /etc/init.d/macset start
   ```

## Configuration

### Operation Modes

MACSet supports two operation modes:

1. **Directory Mode** (default): Monitor directories with file patterns
2. **File Pairs Mode**: Monitor individual source-destination file pairs

### Directory Mode

The service uses a directory-based approach:

```
/etc/macset/
├── sources/                    # Source files with MAC addresses
│   ├── network_devices.txt     # Primary network devices
│   ├── guest_devices.txt       # Guest network devices
│   └── iot_devices.txt         # IoT network devices
├── outputs/                    # Processed output files
│   ├── network_devices_clean.txt
│   ├── guest_devices_clean.txt
│   └── iot_devices_clean.txt
└── config                      # Configuration file
```

### File Pairs Mode

Specify individual source and destination files in different locations:

```
Configuration Format:
"source1|destination1,source2|destination2"

Examples:
"/etc/network.txt|/var/output.txt,/etc/guest.txt|/tmp/guest_clean.txt"
"/home/user/devices.txt|/var/lib/macset/processed.txt"
```

### Source File Format

Create your source files with MAC addresses and comments:

**network_devices.txt:**
```
# Network Devices - Primary Network
# Add MAC addresses for devices on the main network
00:11:22:33:44:55    # iPhone 12 Pro
aa:bb:cc:dd:ee:ff    # Samsung Galaxy S21
12:34:56:78:9a:bc    # Dell Laptop
```

**guest_devices.txt:**
```
# Guest Devices - Guest Network
# Add MAC addresses for guest devices
a1:b2:c3:d4:e5:f6    # Guest Phone 1
f1:e2:d3:c4:b5:a6    # Guest Laptop 1
```

### Output Files

The processed files will be generated with clean MAC addresses:

**network_devices_clean.txt:**
```
00:11:22:33:44:55
aa:bb:cc:dd:ee:ff
12:34:56:78:9a:bc
```

**guest_devices_clean.txt:**
```
a1:b2:c3:d4:e5:f6
f1:e2:d3:c4:b5:a6
```

## Usage

### Service Management

```bash
# Start the service
/etc/init.d/macset start

# Stop the service
/etc/init.d/macset stop

# Restart the service
/etc/init.d/macset restart

# Check service status
/etc/init.d/macset status

# Enable/disable auto-start
/etc/init.d/macset enable
/etc/init.d/macset disable
```

### File Management

```bash
# List source files being monitored
/etc/init.d/macset sources

# List processed output files
/etc/init.d/macset outputs

# Process all files once (without monitoring)
/etc/init.d/macset process

# View configuration
/etc/init.d/macset config
```

### Manual Processing

#### Directory Mode
```bash
# Process all files in a directory
macset-processor -p /path/to/sources /path/to/outputs

# Monitor with custom file pattern
macset-processor -m -f "*.mac" /path/to/sources /path/to/outputs
```

#### File Pairs Mode
```bash
# Process individual file pairs
macset-processor -p -F "/etc/network.txt|/var/output.txt,/etc/guest.txt|/tmp/guest_clean.txt"

# Monitor individual file pairs
macset-processor -m -F "/etc/network.txt|/var/output.txt,/etc/guest.txt|/tmp/guest_clean.txt"
```

#### Legacy Single File Mode
```bash
# Process a single file (legacy mode)
macset-processor -s input.txt output.txt
```

## Logging

Logs are written to `/var/log/macset/macset.log` and include:
- Service start/stop events
- File change detection for each monitored file
- Processing statistics per file
- Error messages and warnings

## File Structure

```
/etc/macset/
├── sources/                    # Source files with comments (directory mode)
├── outputs/                    # Processed output files (directory mode)
└── config                      # Configuration file

/var/log/macset/
└── macset.log                 # Service logs

/usr/bin/
└── macset-processor           # Main processing script

/etc/init.d/
└── macset                     # OpenWrt init script
```

## Configuration Options

Edit `/etc/macset/config` to customize behavior:

```bash
# Operation mode
OPERATION_MODE="directory"     # "directory" or "pairs"

# Directory mode settings
SOURCE_DIR="/etc/macset/sources"
OUTPUT_DIR="/etc/macset/outputs"
FILE_PATTERN="*.txt"

# File pairs mode settings
FILE_PAIRS=""                  # "src1|dest1,src2|dest2"

# General settings
LOG_FILE="/var/log/macset/macset.log"
MONITOR_INTERVAL=5
DEBUG=0
```

## Advanced Usage

### Custom File Patterns

Monitor specific file types:

```bash
# Monitor only .mac files
FILE_PATTERN="*.mac"

# Monitor files with specific prefix
FILE_PATTERN="mac_*"

# Monitor multiple patterns
FILE_PATTERN="*.txt *.mac"
```

### Individual File Pairs

Use file pairs for maximum flexibility:

```bash
# Configuration example
OPERATION_MODE="pairs"
FILE_PAIRS="/etc/network.txt|/var/output.txt,/etc/guest.txt|/tmp/guest_clean.txt,/home/user/devices.txt|/var/lib/macset/processed.txt"
```

### Multiple Service Instances

You can run multiple instances for different purposes:

```bash
# Create separate configs
cp /etc/macset/config /etc/macset/config.guest
cp /etc/macset/config /etc/macset/config.iot

# Edit configs to use different file pairs
# Then run separate instances
macset-processor -m -F "/etc/guest.txt|/tmp/guest_clean.txt" &
macset-processor -m -F "/etc/iot.txt|/tmp/iot_clean.txt" &
```

### Integration with Network Services

Use the processed files with other OpenWrt services:

```bash
# Use with iptables
while read -r mac; do
    iptables -A FORWARD -m mac --mac-source "$mac" -j ACCEPT
done < /etc/macset/outputs/network_devices_clean.txt

# Use with dnsmasq
cat /etc/macset/outputs/guest_devices_clean.txt | while read -r mac; do
    echo "dhcp-host=$mac,guest,192.168.2.100,24h"
done >> /etc/dnsmasq.conf
```

## Troubleshooting

### Common Issues

1. **Service won't start**: Check if required commands are available
2. **No output files generated**: Verify source files exist and have valid MAC addresses
3. **Permission denied**: Ensure proper file permissions on source and output directories
4. **Files not being monitored**: Check FILE_PATTERN in configuration
5. **File pairs not working**: Verify FILE_PAIRS format and file paths

### Debug Mode

Enable debug logging by setting `DEBUG=1` in the config file and restart the service.

### File Change Detection

If files aren't being processed when changed:
1. Check file permissions
2. Verify the file matches the FILE_PATTERN (directory mode)
3. Verify file paths in FILE_PAIRS (file pairs mode)
4. Check logs for error messages
5. Try manual processing with `macset-processor -p`

## License

This project is released under the MIT License. See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Version History

- **v1.4.0**: Added individual file pairs support, enhanced flexibility
- **v1.3.0**: Added multi-file support, directory-based structure, enhanced monitoring
- **v1.2.0**: Added configuration file support and improved logging
- **v1.1.0**: Enhanced error handling and OpenWrt integration
- **v1.0.0**: Initial release with basic file monitoring and MAC address processing

## Author

Jun Zhang

**Date:** 2025-07-22

## Support

For support and questions, please open an issue on the project repository. 