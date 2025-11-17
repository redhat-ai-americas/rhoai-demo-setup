#!/bin/bash

# RhoAI Demo Setup - Single Component Installation Script

set -e  # Exit on any error

# Create log directory and file with timestamp
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/install-component_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log to file
log_to_file() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Log to both console and file with color
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

# Validate kustomize directory
validate_kustomize_directory() {
    local kustomize_dir="$1"
    
    # Check if directory exists
    if [ ! -d "$kustomize_dir" ]; then
        error "Directory '$kustomize_dir' does not exist"
        return 1
    fi
    
    # Check if kustomization.yaml or kustomization.yml exists
    if [ ! -f "$kustomize_dir/kustomization.yaml" ] && [ ! -f "$kustomize_dir/kustomization.yml" ]; then
        error "Directory '$kustomize_dir' is not a valid kustomize directory (missing kustomization.yaml or kustomization.yml)"
        return 1
    fi
    
    # Check if kustomize command can build the directory
    if ! kustomize build "$kustomize_dir" > /dev/null 2>&1; then
        error "Directory '$kustomize_dir' contains invalid kustomize configuration"
        return 1
    fi
    
    return 0
}

# Apply component with retry
apply_component() {
    local component_path="$1"
    local component_name="$2"
    local max_attempts=10
    local attempt=1
    
    log "Installing $component_name..."
    
    # List and log all files in the kustomize directory
    log "Files in kustomize directory '$component_path':"
    # log_to_file "Files in kustomize directory '$component_path':"
    
    if [ -d "$component_path" ]; then
        # List all files with their relative paths
        find "$component_path" -type f -name "*.yaml" -o -name "*.yml" -o -name "*.json" | sort | while read -r file; do
            local relative_file="${file#$component_path/}"
            log "  - $relative_file"
            # log_to_file "  - $relative_file"
        done
        
        # Also show any other files that might be relevant
        find "$component_path" -type f ! -name "*.yaml" ! -name "*.yml" ! -name "*.json" | sort | while read -r file; do
            local relative_file="${file#$component_path/}"
            log "  - $relative_file (non-YAML/JSON)"
            #log_to_file "  - $relative_file (non-YAML/JSON)"
        done
    else
        warning "Directory '$component_path' does not exist"
        log_to_file "WARNING: Directory '$component_path' does not exist"
    fi
    
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

# Show usage
show_usage() {
    echo "Usage: $0 <kustomize-directory>"
    echo ""
    echo "Install a single component from a kustomize directory"
    echo ""
    echo "Arguments:"
    echo "  kustomize-directory    Path to the kustomize directory containing kustomization.yaml"
    echo ""
    echo "Examples:"
    echo "  $0 components/00-prereqs"
    echo "  $0 components/01-admin-user"
    echo "  $0 components/03-gpu-operators"
    echo ""
    echo "The script will:"
    echo "  1. Validate that the directory is a valid kustomize directory"
    echo "  2. Check OpenShift CLI (oc) is available and user is logged in"
    echo "  3. Apply the kustomize configuration to the cluster"
    echo "  4. Log all operations to a timestamped log file"
}

main() {
    # Check if kustomize directory argument is provided
    if [ $# -eq 0 ]; then
        error "No kustomize directory provided"
        echo ""
        show_usage
        exit 1
    fi
    
    local kustomize_dir="$1"
    
    # Initialize log file
    log_to_file "=================================================="
    log_to_file "RhoAI Demo Setup Single Component Installation Started"
    log_to_file "Target directory: $kustomize_dir"
    log_to_file "Log file: $LOG_FILE"
    log_to_file "=================================================="
    
    log "Starting RhoAI Demo Setup Single Component Installation"
    log "Target directory: $kustomize_dir"
    log "Log file: $LOG_FILE"
    log "=================================================="
    
    # Validate kustomize directory
    log "Validating kustomize directory: $kustomize_dir"
    if ! validate_kustomize_directory "$kustomize_dir"; then
        error "Invalid kustomize directory. Exiting."
        exit 1
    fi
    success "Kustomize directory validation passed"
    
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
    # log_to_file "Connected to cluster: $cluster_info"
    
    # Extract component name from directory path
    local component_name=$(basename "$kustomize_dir")
    
    # Install the component
    if ! apply_component "$kustomize_dir" "$component_name"; then
        error "Failed to install $component_name. Exiting."
        exit 1
    fi
    
    success "Component '$component_name' installed successfully!"
 
    log "=================================================="
    log "Installation completed successfully at $(date)"
    log "=================================================="
}

# Run main function
main "$@"
