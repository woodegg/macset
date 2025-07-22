# Changelog

All notable changes to the MACSet project will be documented in this file.

**Author:** Jun Zhang  
**Date:** 2025-07-22

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2024-01-15

### Added
- **Individual file pairs support**: Specify source and destination files in different locations
- **Operation modes**: Support for both directory-based and file pairs monitoring
- **Enhanced flexibility**: Process files from any location on the filesystem
- **File pairs configuration**: New FILE_PAIRS setting for individual file specifications
- **Operation mode selection**: Choose between "directory" and "pairs" modes
- **Separator configuration**: Customizable separators for file pairs parsing
- **Enhanced service management**: Better support for file pairs in init.d script
- **Improved documentation**: Comprehensive examples for file pairs usage

### Changed
- **Configuration structure**: Added new options for file pairs mode
- **Service startup**: Enhanced logic to handle both operation modes
- **File processing**: Improved parsing for individual file pairs
- **Status reporting**: Better display of file pairs information
- **Error handling**: Enhanced validation for file pairs configuration

### Fixed
- **File pairs parsing**: Fixed comma and pipe separator handling
- **Path validation**: Improved checking for file pair paths
- **Service compatibility**: Ensured backward compatibility with existing setups

## [1.3.0] - 2024-01-10

### Added
- **Multi-file support**: Monitor and process multiple source files simultaneously
- **Directory-based structure**: Source and output directories instead of single files
- **File pattern matching**: Configurable patterns to monitor specific file types
- **Enhanced file monitoring**: Track changes across multiple files with modification time tracking
- **New service commands**: `sources`, `outputs`, and `process` commands for better management
- **Sample source files**: Multiple example files for different network segments
- **Legacy mode support**: Backward compatibility with single file processing
- **Recursive directory scanning**: Optional support for subdirectory processing
- **File change detection methods**: Configurable detection (mtime vs hash)
- **Maximum file limits**: Prevent resource exhaustion with large numbers of files
- **Output naming conventions**: Flexible naming for processed files

### Changed
- **Architecture**: Moved from single file to directory-based monitoring
- **Configuration**: Updated config file structure for multi-file support
- **Service management**: Enhanced init.d script with new commands and better status reporting
- **Installation**: Updated installation script to handle directory structure
- **Documentation**: Comprehensive updates for multi-file usage and examples
- **Logging**: Enhanced logging to track multiple files and processing statistics

### Fixed
- **File tracking**: Improved file change detection reliability
- **Resource usage**: Better memory management for multiple files
- **Error handling**: Enhanced error reporting for directory operations
- **Service stability**: Improved process management and cleanup

## [1.2.0] - 2024-01-05

### Added
- Enhanced configuration file support with additional options
- Improved logging with color-coded output and debug mode
- Better error handling and validation
- Service status monitoring and reporting
- Automatic directory creation and file backup options
- Comprehensive installation script with dependency checking
- Makefile for easy building and packaging
- Sample MAC addresses file for testing
- MIT License for open source distribution

### Changed
- Improved MAC address validation with support for both colon and dash formats
- Enhanced OpenWrt init.d service integration using procd
- Better file monitoring with configurable intervals
- More robust signal handling for graceful shutdown
- Updated documentation with comprehensive usage examples

### Fixed
- Fixed potential race conditions in file processing
- Improved error handling for missing dependencies
- Better handling of invalid MAC address formats
- Fixed service startup issues on some OpenWrt systems

## [1.1.0] - 2024-01-01

### Added
- Configuration file support for customizing behavior
- Logging functionality for debugging and monitoring
- Service management commands (start, stop, restart, status)
- Basic error handling and validation

### Changed
- Improved file monitoring efficiency
- Better comment processing and whitespace handling
- Enhanced OpenWrt service integration

### Fixed
- Fixed issues with inline comment processing
- Improved handling of empty lines and whitespace

## [1.0.0] - 2024-01-01

### Added
- Initial release of MACSet MAC Address Processor
- File monitoring functionality
- MAC address validation and processing
- Comment removal and whitespace cleaning
- OpenWrt init.d service integration
- Basic command-line interface
- Support for both colon and dash MAC address formats

### Features
- Real-time file monitoring
- Automatic processing of MAC addresses
- Comment and whitespace removal
- Service auto-start on boot
- Process management and monitoring 