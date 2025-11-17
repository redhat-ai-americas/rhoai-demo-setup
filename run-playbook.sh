#!/bin/bash

# RhoAI Demo Setup - Generic Ansible Playbook Runner with Logging
# Usage: ./run-playbook.sh <playbook-path> [ansible-options]

# Create log directory
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Check if playbook path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <playbook-path> [ansible-options]"
    echo ""
    echo "Examples:"
    echo "  $0 playbooks/cluster-setup.ansible.yml"
    echo "  $0 playbooks/gpu-setup.ansible.yml"
    echo "  $0 playbooks/minio-setup.ansible.yml -v"
    echo "  $0 playbooks/demo-vllm.ansible.yml -vv"
    exit 1
fi

PLAYBOOK="$1"
shift  # Remove first argument, rest are ansible options

# Generate timestamp for log file
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
PLAYBOOK_NAME=$(basename "$PLAYBOOK" .ansible.yml | sed 's/\.ansible$//')
LOG_FILE="$LOG_DIR/${PLAYBOOK_NAME}_${TIMESTAMP}.log"

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
if [ ! -f "$PLAYBOOK" ]; then
    error "Playbook not found: $PLAYBOOK"
    exit 1
fi

# Initialize log file
log "=================================================="
log "RhoAI Demo Setup - Ansible Playbook Execution"
log "=================================================="
log "Playbook: $PLAYBOOK"
log "Log file: $LOG_FILE"
log "Start time: $(date)"
if [ $# -gt 0 ]; then
    log "Ansible options: $*"
fi
log "=================================================="
log ""

# Run ansible-playbook with tee to capture all output
log "Starting ansible-playbook execution..."
log "All output will be logged to: $LOG_FILE"
log ""

# Execute playbook and log everything
# Default to -v if no verbosity option is provided
if [ $# -eq 0 ]; then
    ANSIBLE_OPTS="-v"
else
    ANSIBLE_OPTS="$@"
fi

if ansible-playbook "$PLAYBOOK" $ANSIBLE_OPTS 2>&1 | tee -a "$LOG_FILE"; then
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

