#!/bin/bash

# RhoAI Demo Setup - Component Installation Script

set -e  # Exit on any error

# Create log file with timestamp
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="install-components_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log to both console and file
log_to_file() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Function to log to both console and file with color
log_both() {
    local message="$1"
    echo -e "$message"
    # Strip color codes for log file
    echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# Logging function
log() {
    log_both "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    log_both "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

warning() {
    log_both "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

error() {
    log_both "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

# Function to wait for component to be ready
wait_for_component() {
    local component_name="$1"
    local max_attempts=30
    local attempt=1
    return 0
}

# Function to apply component with retry
apply_component() {
    local component_path="$1"
    local component_name="$2"
    local max_attempts=5
    local attempt=1
    
    log "Installing $component_name..."
    
    while [ $attempt -le $max_attempts ]; do
        log_to_file "Attempt $attempt: Installing $component_name from $component_path"
        if oc apply -k "$component_path" >> "$LOG_FILE" 2>&1; then
            success "$component_name installed successfully"
            log_to_file "SUCCESS: $component_name installed successfully"
            return 0
        else
            warning "Attempt $attempt failed for $component_name, retrying in 10 seconds..."
            log_to_file "WARNING: Attempt $attempt failed for $component_name, retrying in 10 seconds..."
            sleep 10
            ((attempt++))
        fi
    done
    
    error "Failed to install $component_name after $max_attempts attempts"
    return 1
}

# Main installation function
main() {
    # Initialize log file
    log_to_file "=================================================="
    log_to_file "RhoAI Demo Setup Component Installation Started"
    log_to_file "Log file: $LOG_FILE"
    log_to_file "=================================================="
    
    log "Starting RhoAI Demo Setup Component Installation"
    log "Log file: $LOG_FILE"
    log "=================================================="
    
    # Check if oc command is available
    if ! command -v oc &> /dev/null; then
        error "OpenShift CLI (oc) is not installed or not in PATH"
        log_to_file "ERROR: OpenShift CLI (oc) is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're logged in to a cluster
    if ! oc whoami &> /dev/null; then
        error "Not logged in to OpenShift cluster. Please run 'oc login' first"
        log_to_file "ERROR: Not logged in to OpenShift cluster. Please run 'oc login' first"
        exit 1
    fi
    
    local cluster_info=$(oc whoami --show-server)
    log "Connected to cluster: $cluster_info"
    log_to_file "Connected to cluster: $cluster_info"
    
    # Define components in installation order
    declare -a components=(
        "components/00-prereqs:Prerequisites"
        "components/01-admin-user:Admin User Setup"
        "components/03-gpu-operators:GPU Operators"
        "components/04-gpu-dashboard:GPU Dashboard"
        "components/07-authorino-operator:Authorino Operator"
        "components/08-serverless-operator:Serverless Operator"
        "components/09-servicemesh-operator:Service Mesh Operator"
        "components/10-rhoai-operator:RhoAI Operator"
        "components/11-serving-runtime:Serving Runtime"
        "components/13-monitoring:Monitoring"
    )
    
    # Install each component
    for component in "${components[@]}"; do
        IFS=':' read -r path name <<< "$component"
        
        if [ ! -d "$path" ]; then
            warning "Component directory $path not found, skipping..."
            continue
        fi
        
        if ! apply_component "$path" "$name"; then
            error "Failed to install $name. Stopping installation."
            exit 1
        fi
        
        # Wait for component to be ready (except for the last one)
        # if [ "$component" != "${components[-1]}" ]; then
        #     wait_for_component "$name"
        # fi
        
        echo ""
    done
    
    success "All components installed successfully!"
    log "=================================================="
    log "Installation completed at $(date)"
    
    # Log completion to file
    log_to_file "=================================================="
    log_to_file "Installation completed successfully at $(date)"
    log_to_file "=================================================="
}

# Run main function
main "$@"
