#!/bin/bash

# RhoAI Demo Setup - Multiple Component Installation Script

# Don't use set -e here - we want to continue processing even if one component fails
set +e

# Create log directory and file with timestamp
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/install-components_${TIMESTAMP}.log"

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
    
    if [ -d "$component_path" ]; then
        # List all files with their relative paths
        find "$component_path" -type f -name "*.yaml" -o -name "*.yml" -o -name "*.json" | sort | while read -r file; do
            local relative_file="${file#$component_path/}"
            log "  - $relative_file"
        done
        
        # Also show any other files that might be relevant
        find "$component_path" -type f ! -name "*.yaml" ! -name "*.yml" ! -name "*.json" | sort | while read -r file; do
            local relative_file="${file#$component_path/}"
            log "  - $relative_file (non-YAML/JSON)"
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
    echo "Usage: $0 <kustomize-directory> [<kustomize-directory> ...]"
    echo ""
    echo "Install multiple components from kustomize directories"
    echo ""
    echo "Arguments:"
    echo "  kustomize-directory    Path to one or more kustomize directories containing kustomization.yaml"
    echo ""
    echo "Examples:"
    echo "  $0 components/00-prereqs components/01-admin-user"
    echo "  $0 components/00-prereqs components/01-admin-user components/03-gpu-operators"
    echo "  $0 components/00-prereqs components/01-admin-user components/02-gpu-node components/03-gpu-operators"
    echo ""
    echo "The script will:"
    echo "  1. Validate that each directory is a valid kustomize directory"
    echo "  2. Check OpenShift CLI (oc) is available and user is logged in"
    echo "  3. Apply each kustomize configuration to the cluster sequentially"
    echo "  4. Log all operations to a timestamped log file"
    echo "  5. Provide a summary of successful and failed installations"
}

main() {
    # Check if at least one kustomize directory argument is provided
    if [ $# -eq 0 ]; then
        error "No kustomize directories provided"
        echo ""
        show_usage
        exit 1
    fi
    
    local component_dirs=("$@")
    local total_components=${#component_dirs[@]}
    
    # Arrays to track results
    local successful_components=()
    local failed_components=()
    
    # Initialize log file
    log_to_file "=================================================="
    log_to_file "RhoAI Demo Setup Multiple Component Installation Started"
    log_to_file "Total components to install: $total_components"
    log_to_file "Components: ${component_dirs[*]}"
    log_to_file "Log file: $LOG_FILE"
    log_to_file "=================================================="
    
    log "Starting RhoAI Demo Setup Multiple Component Installation"
    log "Total components to install: $total_components"
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
    log ""
    
    # Validate all kustomize directories first
    log "Validating all kustomize directories..."
    local validation_failed=false
    for kustomize_dir in "${component_dirs[@]}"; do
        log "Validating: $kustomize_dir"
        if ! validate_kustomize_directory "$kustomize_dir"; then
            error "Invalid kustomize directory: $kustomize_dir"
            validation_failed=true
        else
            success "Validation passed: $kustomize_dir"
        fi
    done
    
    if [ "$validation_failed" = true ]; then
        error "One or more kustomize directories failed validation. Exiting."
        exit 1
    fi
    
    log ""
    log "All validations passed. Starting installation..."
    log "=================================================="
    log ""
    
    # Install each component
    local component_num=1
    for kustomize_dir in "${component_dirs[@]}"; do
        local component_name=$(basename "$kustomize_dir")
        log "=================================================="
        log "Component $component_num of $total_components: $component_name"
        log "=================================================="
        
        if apply_component "$kustomize_dir" "$component_name"; then
            successful_components+=("$component_name")
            log "Component $component_num/$total_components completed successfully"
        else
            failed_components+=("$component_name")
            error "Component $component_num/$total_components failed"
        fi
        
        log ""
        ((component_num++))
    done
    
    # Print summary
    log "=================================================="
    log "Installation Summary"
    log "=================================================="
    log "Total components: $total_components"
    log "Successful: ${#successful_components[@]}"
    log "Failed: ${#failed_components[@]}"
    log ""
    
    if [ ${#successful_components[@]} -gt 0 ]; then
        success "Successfully installed components:"
        for comp in "${successful_components[@]}"; do
            success "  ✓ $comp"
        done
        log ""
    fi
    
    if [ ${#failed_components[@]} -gt 0 ]; then
        error "Failed components:"
        for comp in "${failed_components[@]}"; do
            error "  ✗ $comp"
        done
        log ""
    fi
    
    log "=================================================="
    log "Installation completed at $(date)"
    log "Log file: $LOG_FILE"
    log "=================================================="
    
    # Exit with appropriate code
    if [ ${#failed_components[@]} -eq 0 ]; then
        success "All components installed successfully!"
        log_to_file "SUCCESS: All $total_components components installed successfully"
        exit 0
    else
        error "Some components failed to install. Check the log file for details: $LOG_FILE"
        log_to_file "ERROR: ${#failed_components[@]} of $total_components components failed to install"
        exit 1
    fi
}

# Run main function
main "$@"

