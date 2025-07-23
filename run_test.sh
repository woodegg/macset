#!/bin/bash
# Wrapper script to run macset-processor with test environment variables

CONFIG_FILE="$1"
PID_FILE="$2"
shift 2

CONFIG_FILE="$CONFIG_FILE" PID_FILE="$PID_FILE" ./macset-processor.sh "$@" 