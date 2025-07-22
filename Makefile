# MACSet Makefile
# 
# This Makefile provides targets for building, installing, and managing
# the MACSet MAC Address Processor for OpenWrt.
#
# Author: Jun Zhang
# Version: 1.4.0
# License: MIT
# Date: 2025-07-22

# Project information
PROJECT_NAME = macset
VERSION = 1.4.0
DESCRIPTION = MAC Address Set Processor for OpenWrt

# Installation paths
PREFIX = /usr
BINDIR = $(PREFIX)/bin
INITDIR = /etc/init.d
CONFIGDIR = /etc/macset
LOGDIR = /var/log/macset

# Files
MAIN_SCRIPT = macset-processor.sh
INIT_SCRIPT = macset
CONFIG_FILE = config
SAMPLE_FILE = mac_addresses.txt
INSTALL_SCRIPT = install.sh
README_FILE = README.md
LICENSE_FILE = LICENSE

# Default target
.PHONY: all
all: help

# Show help
.PHONY: help
help:
	@echo "MACSet $(VERSION) - $(DESCRIPTION)"
	@echo ""
	@echo "Available targets:"
	@echo "  install     Install MACSet to the system"
	@echo "  uninstall   Remove MACSet from the system"
	@echo "  clean       Remove build artifacts"
	@echo "  test        Run basic tests"
	@echo "  package     Create distribution package"
	@echo "  help        Show this help message"
	@echo ""
	@echo "Installation paths:"
	@echo "  Main script: $(BINDIR)/macset-processor"
	@echo "  Init script: $(INITDIR)/macset"
	@echo "  Config dir:  $(CONFIGDIR)"
	@echo "  Log dir:     $(LOGDIR)"

# Install MACSet
.PHONY: install
install:
	@echo "Installing MACSet $(VERSION)..."
	@if [ "$(shell id -u)" -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make install"; \
		exit 1; \
	fi
	@echo "Creating directories..."
	@mkdir -p $(CONFIGDIR) $(LOGDIR)
	@echo "Installing main script..."
	@cp $(MAIN_SCRIPT) $(BINDIR)/macset-processor
	@chmod +x $(BINDIR)/macset-processor
	@echo "Installing init script..."
	@cp $(INIT_SCRIPT) $(INITDIR)/macset
	@chmod +x $(INITDIR)/macset
	@echo "Installing configuration..."
	@if [ ! -f $(CONFIGDIR)/config ]; then \
		cp $(CONFIG_FILE) $(CONFIGDIR)/config; \
	fi
	@if [ ! -f $(CONFIGDIR)/mac_addresses.txt ]; then \
		cp $(SAMPLE_FILE) $(CONFIGDIR)/mac_addresses.txt; \
	fi
	@echo "Setting permissions..."
	@chmod 755 $(CONFIGDIR) $(LOGDIR)
	@chmod 644 $(CONFIGDIR)/config $(CONFIGDIR)/mac_addresses.txt
	@echo "Enabling service..."
	@$(INITDIR)/macset enable
	@echo "Starting service..."
	@$(INITDIR)/macset start
	@echo "Installation completed successfully!"

# Uninstall MACSet
.PHONY: uninstall
uninstall:
	@echo "Uninstalling MACSet..."
	@if [ "$(shell id -u)" -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make uninstall"; \
		exit 1; \
	fi
	@echo "Stopping service..."
	@$(INITDIR)/macset stop 2>/dev/null || true
	@echo "Disabling service..."
	@$(INITDIR)/macset disable 2>/dev/null || true
	@echo "Removing files..."
	@rm -f $(BINDIR)/macset-processor
	@rm -f $(INITDIR)/macset
	@rm -rf $(CONFIGDIR)
	@rm -rf $(LOGDIR)
	@echo "Uninstallation completed!"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -f *.tar.gz
	@rm -f *.zip
	@rm -rf dist/
	@echo "Clean completed!"

# Run basic tests
.PHONY: test
test:
	@echo "Running basic tests..."
	@echo "Testing main script syntax..."
	@bash -n $(MAIN_SCRIPT) || (echo "Syntax error in $(MAIN_SCRIPT)" && exit 1)
	@echo "Testing init script syntax..."
	@bash -n $(INIT_SCRIPT) || (echo "Syntax error in $(INIT_SCRIPT)" && exit 1)
	@echo "Testing install script syntax..."
	@bash -n $(INSTALL_SCRIPT) || (echo "Syntax error in $(INSTALL_SCRIPT)" && exit 1)
	@echo "Testing MAC address processing..."
	@bash $(MAIN_SCRIPT) -p $(SAMPLE_FILE) /tmp/test_output.txt
	@if [ -f /tmp/test_output.txt ]; then \
		echo "Processing test completed successfully"; \
		rm -f /tmp/test_output.txt; \
	else \
		echo "Processing test failed"; \
		exit 1; \
	fi
	@echo "All tests passed!"

# Create distribution package
.PHONY: package
package:
	@echo "Creating distribution package..."
	@mkdir -p dist/$(PROJECT_NAME)-$(VERSION)
	@cp $(MAIN_SCRIPT) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp $(INIT_SCRIPT) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp $(CONFIG_FILE) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp $(SAMPLE_FILE) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp $(INSTALL_SCRIPT) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp $(README_FILE) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp $(LICENSE_FILE) dist/$(PROJECT_NAME)-$(VERSION)/
	@cp Makefile dist/$(PROJECT_NAME)-$(VERSION)/
	@cd dist && tar -czf $(PROJECT_NAME)-$(VERSION).tar.gz $(PROJECT_NAME)-$(VERSION)/
	@cd dist && zip -r $(PROJECT_NAME)-$(VERSION).zip $(PROJECT_NAME)-$(VERSION)/
	@rm -rf dist/$(PROJECT_NAME)-$(VERSION)/
	@echo "Package created: dist/$(PROJECT_NAME)-$(VERSION).tar.gz"
	@echo "Package created: dist/$(PROJECT_NAME)-$(VERSION).zip"

# Show version
.PHONY: version
version:
	@echo "$(VERSION)"

# Show status
.PHONY: status
status:
	@echo "MACSet Status:"
	@echo "=============="
	@if [ -f $(BINDIR)/macset-processor ]; then \
		echo "Main script: $(BINDIR)/macset-processor [INSTALLED]"; \
	else \
		echo "Main script: $(BINDIR)/macset-processor [NOT INSTALLED]"; \
	fi
	@if [ -f $(INITDIR)/macset ]; then \
		echo "Init script: $(INITDIR)/macset [INSTALLED]"; \
	else \
		echo "Init script: $(INITDIR)/macset [NOT INSTALLED]"; \
	fi
	@if [ -d $(CONFIGDIR) ]; then \
		echo "Config dir:  $(CONFIGDIR) [INSTALLED]"; \
	else \
		echo "Config dir:  $(CONFIGDIR) [NOT INSTALLED]"; \
	fi
	@if [ -d $(LOGDIR) ]; then \
		echo "Log dir:     $(LOGDIR) [INSTALLED]"; \
	else \
		echo "Log dir:     $(LOGDIR) [NOT INSTALLED]"; \
	fi
	@if [ -x $(INITDIR)/macset ]; then \
		echo ""; \
		echo "Service status:"; \
		$(INITDIR)/macset status 2>/dev/null || echo "Service not running"; \
	fi 