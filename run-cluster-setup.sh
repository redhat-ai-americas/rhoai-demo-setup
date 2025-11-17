#!/bin/bash

# RhoAI Cluster Setup - Ansible Playbook Runner with Logging

# Create log directory
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Generate timestamp for log file
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/cluster-setup_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} $message"
    echo "[${timestamp}] $message" >> "$LOG_FILE"
}

success() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[${timestamp}] ✓${NC} $message"
    echo "[${timestamp}] SUCCESS: $message" >> "$LOG_FILE"
}

error() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[${timestamp}] ✗${NC} $message"
    echo "[${timestamp}] ERROR: $message" >> "$LOG_FILE"
}

warning() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[${timestamp}] ⚠${NC} $message"
    echo "[${timestamp}] WARNING: $message" >> "$LOG_FILE"
}

# Check if ansible-playbook is available
if ! command -v ansible-playbook &> /dev/null; then
    error "ansible-playbook is not installed or not in PATH"
    exit 1
fi

# Check if playbook exists
PLAYBOOK="playbooks/cluster-setup.ansible.yml"
if [ ! -f "$PLAYBOOK" ]; then
    error "Playbook not found: $PLAYBOOK"
    exit 1
fi

# Initialize log file
log "=================================================="
log "RhoAI Cluster Setup - Ansible Playbook Execution"
log "=================================================="
log "Playbook: $PLAYBOOK"
log "Log file: $LOG_FILE"
log "Start time: $(date)"
log "=================================================="
log ""

# Run ansible-playbook with tee to capture all output
# -v = verbose mode (can use -vv or -vvv for more verbosity)
# tee allows both console output and file logging
log "Starting ansible-playbook execution..."
log "All output will be logged to: $LOG_FILE"
log ""

# Execute playbook and log everything
if ansible-playbook "$PLAYBOOK" -v 2>&1 | tee -a "$LOG_FILE"; then
    success "Playbook execution completed successfully"
    log ""
    log "=================================================="
    log "Execution Summary"
    log "=================================================="
    log "Status: SUCCESS"
    log "End time: $(date)"
    log "Log file: $LOG_FILE"
    log "=================================================="
    exit 0
else
    error "Playbook execution failed"
    log ""
    log "=================================================="
    log "Execution Summary"
    log "=================================================="
    log "Status: FAILED"
    log "End time: $(date)"
    log "Log file: $LOG_FILE"
    log "=================================================="
    log ""
    warning "Check the log file for details: $LOG_FILE"
    exit 1
fi

