#!/bin/bash

# Platform Locals - Master Service Manager
# Complete platform setup and testing script
# Manages all services in the correct order with proper dependencies

set -e

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emojis
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
CROSS="❌"
INFO="ℹ️"
GEAR="⚙️"
DOCKER="🐳"
MONITOR="📊"
SHIELD="🛡️"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Service definitions with dependencies
declare -A SERVICES=(
    ["traefik"]="006-traefik"
    ["minio"]="001-minio"
    ["opensearch"]="002-opensearch"
    ["prometheus"]="007-prometheus"
    ["grafana"]="003-grafana"
    ["alertmanager"]="004-alertmanager"
    ["vault"]="005-vault"
    ["homepage"]="008-homepage"
    ["portainer"]="009-portainer"
    ["zabbix"]="011-zabbix"
    ["ollama"]="012-ollama"
    ["n8n"]="013-n8n"
    ["keycloak"]="014-keycloack"
)

# Service startup order (dependencies first)
SERVICE_ORDER=(
    "traefik"      # Must be first - provides ingress
    "minio"        # Object storage
    "opensearch"   # Search engine
    "prometheus"   # Metrics collection
    "vault"        # Secrets management
    "grafana"      # Monitoring dashboards
    "alertmanager" # Alert management
    "portainer"    # Container management
    "homepage"     # Dashboard
    "zabbix"       # Infrastructure monitoring
    "ollama"       # AI/ML service
    "n8n"          # Workflow automation
    "keycloak"     # Identity management
)

# Service ports for health checks
declare -A SERVICE_PORTS=(
    ["traefik"]="8080"
    ["minio"]="9001"
    ["opensearch"]="9200"
    ["prometheus"]="9090"
    ["grafana"]="3001"
    ["alertmanager"]="9093"
    ["vault"]="8200"
    ["homepage"]="3000"
    ["portainer"]="9000"
    ["zabbix"]="8081"
    ["ollama"]="11434"
    ["n8n"]="5678"
    ["keycloak"]="8080"
)

print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                                                              ║"
    echo -e "║    ${ROCKET} ${PURPLE}PLATFORM LOCALS - SERVICE MANAGER${BLUE}                    ║"
    echo -e "║                                                              ║"
    echo -e "║    Complete Local Development Platform                       ║"
    echo -e "║    Docker-based microservices infrastructure                 ║"
    echo -e "║                                                              ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

log_info() {
    echo -e "${INFO} ${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${CHECK} ${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${WARNING} ${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${CROSS} ${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${GEAR} ${CYAN}[STEP]${NC} $1"
}

check_requirements() {
    log_step "Checking system requirements..."
    
    local requirements_ok=true
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        requirements_ok=false
    else
        log_info "Docker: $(docker --version)"
    fi
    
    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        requirements_ok=false
    else
        if command -v docker compose &> /dev/null; then
            log_info "Docker Compose: $(docker compose version)"
        else
            log_info "Docker Compose: $(docker-compose --version)"
        fi
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        requirements_ok=false
    fi
    
    if [ "$requirements_ok" = false ]; then
        log_error "System requirements not met. Please install missing components."
        exit 1
    fi
    
    log_success "All requirements satisfied"
}

create_networks() {
    log_step "Setting up Docker networks..."
    
    # Create traefik network if it doesn't exist
    if ! docker network ls | grep -q "traefik-network"; then
        docker network create traefik-network
        log_success "Created traefik-network"
    else
        log_info "Network traefik-network already exists"
    fi
    
    # Create other common networks
    local networks=("monitoring" "storage" "security")
    for network in "${networks[@]}"; do
        if ! docker network ls | grep -q "$network"; then
            docker network create "$network" || log_warning "Failed to create network: $network"
        fi
    done
}

setup_directories() {
    log_step "Setting up service directories..."
    
    for service in "${!SERVICES[@]}"; do
        local service_dir="${SERVICES[$service]}"
        local full_path="$SCRIPT_DIR/$service_dir"
        
        if [ -d "$full_path" ]; then
            log_info "Service directory exists: $service_dir"
            
            # Create required subdirectories
            mkdir -p "$full_path/logs" "$full_path/data" "$full_path/config" 2>/dev/null || true
            
            # Set proper permissions for Let's Encrypt if it's Traefik
            if [ "$service" = "traefik" ]; then
                mkdir -p "$full_path/letsencrypt"
                touch "$full_path/letsencrypt/acme.json"
                chmod 600 "$full_path/letsencrypt/acme.json" 2>/dev/null || true
            fi
        else
            log_warning "Service directory not found: $service_dir"
        fi
    done
}

start_service() {
    local service=$1
    local service_dir="${SERVICES[$service]}"
    local full_path="$SCRIPT_DIR/$service_dir"
    
    if [ ! -d "$full_path" ]; then
        log_error "Service directory not found: $service_dir"
        return 1
    fi
    
    log_step "Starting service: $service"
    
    cd "$full_path"
    
    # Check if service has custom manager script
    if [ -f "./${service}-manager.sh" ]; then
        log_info "Using custom manager for $service"
        chmod +x "./${service}-manager.sh"
        "./${service}-manager.sh" start
    elif [ -f "./docker-compose.yaml" ] || [ -f "./docker-compose.yml" ]; then
        # Use docker-compose directly
        if command -v docker compose &> /dev/null; then
            docker compose up -d
        else
            docker-compose up -d
        fi
        log_success "Started $service using docker-compose"
    else
        log_warning "No docker-compose file found for $service"
        return 1
    fi
    
    # Wait a moment for service to start
    sleep 5
    
    # Basic health check
    if check_service_health "$service"; then
        log_success "Service $service is running"
    else
        log_warning "Service $service may not be fully ready yet"
    fi
    
    cd "$SCRIPT_DIR"
}

check_service_health() {
    local service=$1
    local port="${SERVICE_PORTS[$service]}"
    
    if [ -z "$port" ]; then
        return 0  # No port defined, assume healthy
    fi
    
    # Check if port is responding
    if curl -s -m 5 "http://localhost:$port" >/dev/null 2>&1; then
        return 0
    elif nc -z localhost "$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

stop_service() {
    local service=$1
    local service_dir="${SERVICES[$service]}"
    local full_path="$SCRIPT_DIR/$service_dir"
    
    if [ ! -d "$full_path" ]; then
        log_warning "Service directory not found: $service_dir"
        return 1
    fi
    
    log_step "Stopping service: $service"
    
    cd "$full_path"
    
    # Check if service has custom manager script
    if [ -f "./${service}-manager.sh" ]; then
        "./${service}-manager.sh" stop
    elif [ -f "./docker-compose.yaml" ] || [ -f "./docker-compose.yml" ]; then
        if command -v docker compose &> /dev/null; then
            docker compose down
        else
            docker-compose down
        fi
    fi
    
    log_success "Stopped $service"
    cd "$SCRIPT_DIR"
}

start_all_services() {
    print_header
    log_step "Starting all services in dependency order..."
    
    check_requirements
    create_networks
    setup_directories
    
    echo
    log_info "Service startup order:"
    local i=1
    for service in "${SERVICE_ORDER[@]}"; do
        echo "  $i. $service"
        ((i++))
    done
    echo
    
    local failed_services=()
    
    for service in "${SERVICE_ORDER[@]}"; do
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if start_service "$service"; then
            log_success "✓ $service started successfully"
        else
            log_error "✗ Failed to start $service"
            failed_services+=("$service")
        fi
        
        echo
        sleep 2  # Give service time to stabilize before starting next
    done
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "All services started successfully!"
    else
        log_warning "Some services failed to start: ${failed_services[*]}"
    fi
    
    echo
    show_service_status
}

stop_all_services() {
    print_header
    log_step "Stopping all services..."
    
    # Reverse order for stopping
    local reverse_order=()
    for (( i=${#SERVICE_ORDER[@]}-1; i>=0; i-- )); do
        reverse_order+=("${SERVICE_ORDER[i]}")
    done
    
    for service in "${reverse_order[@]}"; do
        stop_service "$service"
        sleep 1
    done
    
    log_success "All services stopped"
}

show_service_status() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                     SERVICE STATUS                          ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    printf "%-15s %-10s %-20s %-30s\n" "SERVICE" "STATUS" "PORT" "URL"
    echo "────────────────────────────────────────────────────────────────────────────"
    
    for service in "${SERVICE_ORDER[@]}"; do
        local port="${SERVICE_PORTS[$service]}"
        local status url
        
        if check_service_health "$service"; then
            status="${GREEN}Running${NC}"
            url="http://localhost:$port"
        else
            status="${RED}Stopped${NC}"
            url="${RED}Not available${NC}"
        fi
        
        printf "%-15s %-18s %-20s %-30s\n" "$service" "$status" "$port" "$url"
    done
    
    echo
}

run_health_checks() {
    print_header
    log_step "Running comprehensive health checks..."
    
    local healthy_count=0
    local total_count=${#SERVICE_ORDER[@]}
    
    for service in "${SERVICE_ORDER[@]}"; do
        local port="${SERVICE_PORTS[$service]}"
        
        echo -n "Testing $service (port $port)... "
        
        if check_service_health "$service"; then
            echo -e "${GREEN}✓ Healthy${NC}"
            healthy_count=$((healthy_count + 1))
        else
            echo -e "${RED}✗ Unhealthy${NC}"
        fi
    done
    
    echo
    echo -e "${BLUE}Health Summary:${NC}"
    echo -e "  Healthy: ${GREEN}$healthy_count${NC}/$total_count"
    echo -e "  Success Rate: ${GREEN}$((healthy_count * 100 / total_count))%${NC}"
    
    if [ $healthy_count -eq $total_count ]; then
        log_success "All services are healthy!"
        return 0
    else
        log_warning "Some services are not responding"
        return 1
    fi
}

show_dashboard() {
    print_header
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    SERVICE DASHBOARD                        ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${PURPLE}📊 Monitoring & Dashboards:${NC}"
    echo -e "  • Traefik Dashboard:    ${CYAN}http://localhost:8080${NC}"
    echo -e "  • Grafana:              ${CYAN}http://localhost:3001${NC}"
    echo -e "  • Prometheus:           ${CYAN}http://localhost:9090${NC}"
    echo -e "  • Portainer:            ${CYAN}http://localhost:9000${NC}"
    echo -e "  • Homepage:             ${CYAN}http://localhost:3000${NC}"
    echo
    
    echo -e "${GREEN}🗄️ Storage & Data:${NC}"
    echo -e "  • MinIO Console:        ${CYAN}http://localhost:9001${NC}"
    echo -e "  • OpenSearch:           ${CYAN}http://localhost:9200${NC}"
    echo
    
    echo -e "${SHIELD} 🛡️ Security & Identity:${NC}"
    echo -e "  • Vault:                ${CYAN}http://localhost:8200${NC}"
    echo -e "  • Keycloak:             ${CYAN}http://localhost:8080${NC}"
    echo
    
    echo -e "${ROCKET} ⚡ Tools & Automation:${NC}"
    echo -e "  • N8N:                  ${CYAN}http://localhost:5678${NC}"
    echo -e "  • Ollama API:           ${CYAN}http://localhost:11434${NC}"
    echo -e "  • Zabbix:               ${CYAN}http://localhost:8081${NC}"
    echo
}

show_help() {
    print_header
    echo -e "${YELLOW}Usage: $0 [command]${NC}"
    echo
    echo -e "${GREEN}Available commands:${NC}"
    echo -e "  ${BLUE}start${NC}           Start all services in order"
    echo -e "  ${BLUE}stop${NC}            Stop all services"
    echo -e "  ${BLUE}restart${NC}         Restart all services"
    echo -e "  ${BLUE}status${NC}          Show service status"
    echo -e "  ${BLUE}health${NC}          Run health checks"
    echo -e "  ${BLUE}dashboard${NC}       Show service URLs"
    echo -e "  ${BLUE}logs${NC} [service]  Show service logs"
    echo -e "  ${BLUE}setup${NC}           Initial platform setup"
    echo -e "  ${BLUE}clean${NC}           Clean up all resources"
    echo -e "  ${BLUE}help${NC}            Show this help"
    echo
    echo -e "${GREEN}Service management:${NC}"
    echo -e "  ${BLUE}start${NC} <service>  Start specific service"
    echo -e "  ${BLUE}stop${NC} <service>   Stop specific service"
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  $0 start              # Start all services"
    echo -e "  $0 start traefik      # Start only Traefik"
    echo -e "  $0 logs prometheus    # Show Prometheus logs"
    echo -e "  $0 health             # Check all services"
    echo
}

show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        log_error "Please specify a service name"
        echo "Available services: ${!SERVICES[*]}"
        return 1
    fi
    
    local service_dir="${SERVICES[$service]}"
    if [ -z "$service_dir" ]; then
        log_error "Unknown service: $service"
        return 1
    fi
    
    local full_path="$SCRIPT_DIR/$service_dir"
    
    if [ ! -d "$full_path" ]; then
        log_error "Service directory not found: $service_dir"
        return 1
    fi
    
    cd "$full_path"
    
    log_info "Showing logs for $service (Ctrl+C to exit):"
    
    if [ -f "./docker-compose.yaml" ] || [ -f "./docker-compose.yml" ]; then
        if command -v docker compose &> /dev/null; then
            docker compose logs -f --tail=50
        else
            docker-compose logs -f --tail=50
        fi
    else
        log_error "No docker-compose file found for $service"
    fi
    
    cd "$SCRIPT_DIR"
}

setup_platform() {
    print_header
    log_step "Initial platform setup..."
    
    check_requirements
    
    # Create necessary directories
    log_step "Creating directory structure..."
    for service in "${!SERVICES[@]}"; do
        local service_dir="${SERVICES[$service]}"
        mkdir -p "$SCRIPT_DIR/$service_dir/logs" "$SCRIPT_DIR/$service_dir/data" "$SCRIPT_DIR/$service_dir/config"
    done
    
    create_networks
    setup_directories
    
    log_success "Platform setup complete!"
    log_info "You can now run: $0 start"
}

clean_platform() {
    print_header
    log_warning "This will remove ALL containers, volumes, and networks!"
    read -p "Are you sure? Type 'YES' to confirm: " confirm
    
    if [ "$confirm" = "YES" ]; then
        log_step "Stopping all services..."
        stop_all_services
        
        log_step "Removing containers and volumes..."
        docker system prune -af --volumes
        
        log_step "Removing custom networks..."
        docker network rm traefik-network monitoring storage security 2>/dev/null || true
        
        log_success "Platform cleaned!"
    else
        log_info "Operation cancelled"
    fi
}

# Main script logic
main() {
    case "${1:-help}" in
        start)
            if [ -n "$2" ] && [ -n "${SERVICES[$2]}" ]; then
                start_service "$2"
            else
                start_all_services
            fi
            ;;
        stop)
            if [ -n "$2" ] && [ -n "${SERVICES[$2]}" ]; then
                stop_service "$2"
            else
                stop_all_services
            fi
            ;;
        restart)
            stop_all_services
            sleep 3
            start_all_services
            ;;
        status)
            show_service_status
            ;;
        health)
            run_health_checks
            ;;
        dashboard)
            show_dashboard
            ;;
        logs)
            show_logs "$2"
            ;;
        setup)
            setup_platform
            ;;
        clean)
            clean_platform
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"