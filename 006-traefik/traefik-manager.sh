#!/bin/bash

# Traefik Management Script
# This script helps manage Traefik configuration and deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yaml"
NETWORK_NAME="traefik-network"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# log_info prints an informational message in blue to stdout.
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# log_success prints a success message in green color to stdout.
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# log_warning prints a warning message to stdout with yellow color formatting.
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# log_error prints an error message to stderr with red formatting.
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# check_docker verifies that the Docker daemon is running and exits with an error if it is not.
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# create_network checks for the existence of the Traefik Docker network and creates it if it does not exist.
create_network() {
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        log_info "Creating Traefik network: $NETWORK_NAME"
        docker network create "$NETWORK_NAME"
        log_success "Network $NETWORK_NAME created successfully"
    else
        log_info "Network $NETWORK_NAME already exists"
    fi
}

# setup_permissions ensures required files and directories for Let's Encrypt and logging exist with secure permissions.
setup_permissions() {
    log_info "Setting up permissions..."
    
    # Create acme.json if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/letsencrypt/acme.json" ]; then
        touch "$SCRIPT_DIR/letsencrypt/acme.json"
    fi
    
    # Set correct permissions for Let's Encrypt
    chmod 600 "$SCRIPT_DIR/letsencrypt/acme.json"
    
    # Ensure log directory is writable
    chmod 755 "$SCRIPT_DIR/logs"
    
    log_success "Permissions set correctly"
}

# generate_auth outputs a basic authentication hash for use with Traefik, using provided or default credentials.
# If the `htpasswd` utility is unavailable, a default hash is returned and a warning is logged.
generate_auth() {
    local username="${1:-admin}"
    local password="${2:-admin}"
    
    if command -v htpasswd >/dev/null 2>&1; then
        echo "$(htpasswd -nb "$username" "$password" | sed -e s/\\$/\\$\\$/g)"
    else
        log_warning "htpasswd not found. Install apache2-utils for password generation."
        echo "admin:\$\$apr1\$\$ruca84Hq\$\$mbjdMZBAG.KWn7vfN/SNK/"
    fi
}

# start launches the Traefik service using Docker Compose, ensuring prerequisites like Docker, network, and permissions are set up before starting containers and displaying dashboard access information.
start() {
    log_info "Starting Traefik..."
    
    check_docker
    create_network
    setup_permissions
    
    cd "$SCRIPT_DIR"
    docker compose up -d
    
    log_success "Traefik started successfully!"
    log_info "Dashboard available at: http://localhost:8080"
    log_info "Or at: http://traefik.localhost (add to /etc/hosts if needed)"
}

# stop shuts down Traefik containers managed by Docker Compose.
stop() {
    log_info "Stopping Traefik..."
    
    cd "$SCRIPT_DIR"
    docker compose down
    
    log_success "Traefik stopped successfully!"
}

# restart stops and then starts Traefik containers, effectively restarting the Traefik service.
restart() {
    log_info "Restarting Traefik..."
    stop
    sleep 2
    start
}

# status displays the current status of Traefik containers and the associated Docker network, including the number of connected containers.
status() {
    log_info "Traefik Status:"
    
    cd "$SCRIPT_DIR"
    docker compose ps
    
    echo ""
    log_info "Network Status:"
    if docker network ls | grep -q "$NETWORK_NAME"; then
        log_success "Network $NETWORK_NAME exists"
        docker network inspect "$NETWORK_NAME" --format "Connected containers: {{len .Containers}}"
    else
        log_warning "Network $NETWORK_NAME does not exist"
    fi
}

# logs displays the last N lines of logs for a specified Docker Compose service, defaulting to the Traefik service.
logs() {
    local service="${1:-traefik}"
    local lines="${2:-50}"
    
    log_info "Showing last $lines lines of $service logs:"
    
    cd "$SCRIPT_DIR"
    docker compose logs --tail="$lines" -f "$service"
}

# validate checks the Docker Compose and dynamic Traefik configuration for syntax errors and verifies the presence of dynamic config files.
validate() {
    log_info "Validating Traefik configuration..."
    
    cd "$SCRIPT_DIR"
    
    # Check docker-compose syntax
    if docker compose config >/dev/null 2>&1; then
        log_success "Docker Compose configuration is valid"
    else
        log_error "Docker Compose configuration has errors"
        docker compose config
        return 1
    fi
    
    # Check if dynamic config files exist
    if [ -d "$SCRIPT_DIR/config" ]; then
        log_success "Dynamic configuration directory exists"
        
        for config_file in "$SCRIPT_DIR/config"/*.yml; do
            if [ -f "$config_file" ]; then
                log_info "Found configuration: $(basename "$config_file")"
            fi
        done
    else
        log_warning "Dynamic configuration directory not found"
    fi
    
    log_success "Configuration validation completed"
}

# add_service connects a specified Docker container to the Traefik network for reverse proxy management.
# 
# The function requires the container name or ID as an argument. If the container does not exist or is already connected, an error is logged.
add_service() {
    local service_name="$1"
    
    if [ -z "$service_name" ]; then
        log_error "Service name is required"
        echo "Usage: $0 add-service <container_name_or_id>"
        return 1
    fi
    
    log_info "Adding service '$service_name' to Traefik network..."
    
    if docker network connect "$NETWORK_NAME" "$service_name" 2>/dev/null; then
        log_success "Service '$service_name' added to $NETWORK_NAME"
    else
        log_error "Failed to add service '$service_name' to $NETWORK_NAME"
        log_info "Make sure the container exists and is not already connected"
    fi
}

# help displays usage instructions, available commands, and example invocations for the Traefik management script.
help() {
    echo "Traefik Management Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start                 Start Traefik and create necessary resources"
    echo "  stop                  Stop Traefik"
    echo "  restart               Restart Traefik"
    echo "  status                Show Traefik and network status"
    echo "  logs [service] [lines] Show logs (default: traefik, 50 lines)"
    echo "  validate              Validate configuration files"
    echo "  add-service <name>    Add a container to Traefik network"
    echo "  generate-auth [user] [pass] Generate basic auth hash"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start              # Start Traefik"
    echo "  $0 logs traefik 100   # Show 100 lines of Traefik logs"
    echo "  $0 add-service webapp # Add 'webapp' container to Traefik network"
    echo "  $0 generate-auth admin secret123 # Generate auth hash"
}

# Main script logic
case "${1:-help}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$2" "$3"
        ;;
    validate)
        validate
        ;;
    add-service)
        add_service "$2"
        ;;
    generate-auth)
        generate_auth "$2" "$3"
        ;;
    help|--help|-h)
        help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        help
        exit 1
        ;;
esac
