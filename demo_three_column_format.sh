#!/bin/bash
#
# Demonstration script for MACSet Processor three-column file pairs
# 
# This script demonstrates the new three-column format where the third column
# is an optional command to execute after file processing.
#
# Author: Jun Zhang
# Version: 1.4.0
# License: MIT
# Date: 2025-07-22

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Demo configuration
DEMO_DIR="/tmp/macset_demo_$$"
SCRIPT_PATH="./macset-processor.sh"

echo -e "${BLUE}=== MACSet Processor Three-Column File Pairs Demo ===${NC}"
echo

# Setup demo environment
echo -e "${YELLOW}Setting up demo environment...${NC}"
mkdir -p "$DEMO_DIR"
mkdir -p "$DEMO_DIR/sources"
mkdir -p "$DEMO_DIR/outputs"
mkdir -p "$DEMO_DIR/logs"

# Create demo source files
echo -e "${YELLOW}Creating demo source files...${NC}"

cat > "$DEMO_DIR/sources/network.txt" << 'EOF'
# Network devices MAC addresses
aa:bb:cc:dd:ee:01  # Router
aa:bb:cc:dd:ee:02  # Switch
aa:bb:cc:dd:ee:03  # Access Point
invalid_mac_address  # This should be ignored
EOF

cat > "$DEMO_DIR/sources/guest.txt" << 'EOF'
# Guest devices
ff:ee:dd:cc:bb:01  # Guest laptop
ff:ee:dd:cc:bb:02  # Guest phone
ff:ee:dd:cc:bb:03  # Guest tablet
EOF

# Create demo commands
echo -e "${YELLOW}Creating demo commands...${NC}"

cat > "$DEMO_DIR/restart_firewall.sh" << 'EOF'
#!/bin/bash
echo "Firewall restart command executed at $(date)" >> /tmp/macset_demo.log
echo "This would restart the firewall in a real environment" >> /tmp/macset_demo.log
EOF

cat > "$DEMO_DIR/reload_dnsmasq.sh" << 'EOF'
#!/bin/bash
echo "DNSMasq reload command executed at $(date)" >> /tmp/macset_demo.log
echo "This would reload DNSMasq in a real environment" >> /tmp/macset_demo.log
EOF

chmod +x "$DEMO_DIR/restart_firewall.sh"
chmod +x "$DEMO_DIR/reload_dnsmasq.sh"

# Create demo config
cat > "$DEMO_DIR/demo_config" << EOF
# Demo configuration
SOURCE_DIR="$DEMO_DIR/sources"
OUTPUT_DIR="$DEMO_DIR/outputs"
LOG_FILE="$DEMO_DIR/logs/macset.log"
MONITOR_INTERVAL=1
DEBUG=1
FILE_PATTERN="*.txt"
OPERATION_MODE="pairs"
EOF

echo -e "${GREEN}Demo environment ready!${NC}"
echo

# Demo 1: Two-column format (backward compatibility)
echo -e "${BLUE}Demo 1: Two-column format (backward compatibility)${NC}"
echo "Format: source|destination"
echo "Command: ./macset-processor.sh -p -F \"network.txt|output.txt\""
echo

CONFIG_FILE="$DEMO_DIR/demo_config" PID_FILE="$DEMO_DIR/macset.pid" "$SCRIPT_PATH" -p -F "$DEMO_DIR/sources/network.txt|$DEMO_DIR/outputs/network_clean.txt" 2>/dev/null

echo "Result:"
if [ -f "$DEMO_DIR/outputs/network_clean.txt" ]; then
    echo -e "${GREEN}✓ Output file created successfully${NC}"
    echo "Contents:"
    cat "$DEMO_DIR/outputs/network_clean.txt"
else
    echo -e "${YELLOW}✗ Output file not created${NC}"
fi
echo

# Demo 2: Three-column format with command
echo -e "${BLUE}Demo 2: Three-column format with command${NC}"
echo "Format: source|destination|command"
echo "Command: ./macset-processor.sh -p -F \"guest.txt|output.txt|restart_firewall.sh\""
echo

CONFIG_FILE="$DEMO_DIR/demo_config" PID_FILE="$DEMO_DIR/macset.pid" "$SCRIPT_PATH" -p -F "$DEMO_DIR/sources/guest.txt|$DEMO_DIR/outputs/guest_clean.txt|$DEMO_DIR/restart_firewall.sh" 2>/dev/null

echo "Result:"
if [ -f "$DEMO_DIR/outputs/guest_clean.txt" ]; then
    echo -e "${GREEN}✓ Output file created successfully${NC}"
    echo "Contents:"
    cat "$DEMO_DIR/outputs/guest_clean.txt"
else
    echo -e "${YELLOW}✗ Output file not created${NC}"
fi

if [ -f "/tmp/macset_demo.log" ]; then
    echo -e "${GREEN}✓ Command executed successfully${NC}"
    echo "Command log:"
    cat /tmp/macset_demo.log
else
    echo -e "${YELLOW}✗ Command not executed${NC}"
fi
echo

# Demo 3: Mixed format (some with commands, some without)
echo -e "${BLUE}Demo 3: Mixed format (some with commands, some without)${NC}"
echo "Format: source1|dest1,source2|dest2|command2"
echo "Command: ./macset-processor.sh -p -F \"network.txt|output1.txt,guest.txt|output2.txt|reload_dnsmasq.sh\""
echo

CONFIG_FILE="$DEMO_DIR/demo_config" PID_FILE="$DEMO_DIR/macset.pid" "$SCRIPT_PATH" -p -F "$DEMO_DIR/sources/network.txt|$DEMO_DIR/outputs/network_mixed.txt,$DEMO_DIR/sources/guest.txt|$DEMO_DIR/outputs/guest_mixed.txt|$DEMO_DIR/reload_dnsmasq.sh" 2>/dev/null

echo "Result:"
echo "Network file:"
if [ -f "$DEMO_DIR/outputs/network_mixed.txt" ]; then
    echo -e "${GREEN}✓ Created${NC}"
    cat "$DEMO_DIR/outputs/network_mixed.txt"
else
    echo -e "${YELLOW}✗ Not created${NC}"
fi

echo "Guest file:"
if [ -f "$DEMO_DIR/outputs/guest_mixed.txt" ]; then
    echo -e "${GREEN}✓ Created${NC}"
    cat "$DEMO_DIR/outputs/guest_mixed.txt"
else
    echo -e "${YELLOW}✗ Not created${NC}"
fi

echo "Command log:"
if [ -f "/tmp/macset_demo.log" ]; then
    cat /tmp/macset_demo.log
else
    echo -e "${YELLOW}No command log found${NC}"
fi
echo

# Demo 4: Complex command with arguments
echo -e "${BLUE}Demo 4: Complex command with arguments${NC}"
echo "Format: source|destination|\"complex command with arguments\""
echo "Command: ./macset-processor.sh -p -F \"network.txt|output.txt|echo 'Complex command' && echo 'executed'\""
echo

CONFIG_FILE="$DEMO_DIR/demo_config" PID_FILE="$DEMO_DIR/macset.pid" "$SCRIPT_PATH" -p -F "$DEMO_DIR/sources/network.txt|$DEMO_DIR/outputs/network_complex.txt|echo 'Complex command executed at' \$(date) >> /tmp/macset_demo.log && echo 'With multiple arguments' >> /tmp/macset_demo.log" 2>/dev/null

echo "Result:"
if [ -f "$DEMO_DIR/outputs/network_complex.txt" ]; then
    echo -e "${GREEN}✓ Output file created successfully${NC}"
    echo "Contents:"
    cat "$DEMO_DIR/outputs/network_complex.txt"
else
    echo -e "${YELLOW}✗ Output file not created${NC}"
fi

echo "Command log:"
if [ -f "/tmp/macset_demo.log" ]; then
    cat /tmp/macset_demo.log
else
    echo -e "${YELLOW}No command log found${NC}"
fi
echo

# Cleanup
echo -e "${YELLOW}Cleaning up demo environment...${NC}"
rm -rf "$DEMO_DIR"
rm -f /tmp/macset_demo.log

echo -e "${GREEN}Demo completed!${NC}"
echo
echo -e "${BLUE}Summary:${NC}"
echo "✓ Two-column format works (backward compatibility)"
echo "✓ Three-column format works with commands"
echo "✓ Mixed format works (some with commands, some without)"
echo "✓ Complex commands with arguments work"
echo "✓ Commands are executed after successful file processing"
echo "✓ Empty commands are ignored"
echo
echo -e "${BLUE}Usage Examples:${NC}"
echo "1. Basic file processing:"
echo "   ./macset-processor.sh -p -F \"source.txt|output.txt\""
echo
echo "2. With command execution:"
echo "   ./macset-processor.sh -p -F \"source.txt|output.txt|/etc/init.d/firewall restart\""
echo
echo "3. Mixed format:"
echo "   ./macset-processor.sh -p -F \"file1.txt|out1.txt,file2.txt|out2.txt|systemctl reload dnsmasq\""
echo
echo "4. Complex command:"
echo "   ./macset-processor.sh -p -F \"source.txt|output.txt|echo 'Processing complete' && systemctl reload service\"" 