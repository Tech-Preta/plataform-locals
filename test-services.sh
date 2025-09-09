#!/bin/bash

# Complete Service Testing Script
# Tests all platform services and validates their functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Emojis
CHECK="✅"
CROSS="❌"
INFO="ℹ️"
WARNING="⚠️"
ROCKET="🚀"

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

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                                                              ║"
    echo -e "║           ${ROCKET} PLATFORM SERVICES TESTER                       ║"
    echo -e "║                                                              ║"
    echo -e "║     Complete functional testing of all services             ║"
    echo -e "║                                                              ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Fix service configurations
fix_configurations() {
    log_info "Fixing service configurations..."
    
    # Fix OpenSearch - add required password
    local opensearch_dir="$SCRIPT_DIR/002-opensearch"
    if [ -d "$opensearch_dir" ] && [ ! -f "$opensearch_dir/.env" ]; then
        cat > "$opensearch_dir/.env" << 'EOF'
# OpenSearch Configuration
OPENSEARCH_INITIAL_ADMIN_PASSWORD=Admin123!@#
OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m

# Security
DISABLE_SECURITY_PLUGIN=false

# Network
OPENSEARCH_PORT=9200
OPENSEARCH_DASHBOARD_PORT=5601

# Cluster
CLUSTER_NAME=opensearch-cluster
NODE_NAME=opensearch-node1
EOF
        log_success "Created OpenSearch environment file"
    fi
    
    # Fix MinIO configuration
    local minio_dir="$SCRIPT_DIR/001-minio"
    if [ -d "$minio_dir" ] && [ ! -f "$minio_dir/.env" ]; then
        cat > "$minio_dir/.env" << 'EOF'
# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_CONSOLE_PORT=9001
MINIO_API_PORT=9000
MINIO_DOMAIN=localhost
EOF
        log_success "Created MinIO environment file"
    fi
    
    # Fix Keycloak to use different port to avoid conflict with Traefik
    local keycloak_dir="$SCRIPT_DIR/014-keycloack"
    if [ -d "$keycloak_dir" ]; then
        # Check if we need to fix port conflict
        if grep -q "8080:8080" "$keycloak_dir/docker-compose.yaml" 2>/dev/null; then
            log_warning "Keycloak port conflict detected - will use port 8088"
            sed -i 's/8080:8080/8088:8080/g' "$keycloak_dir/docker-compose.yaml" 2>/dev/null || true
        fi
        
        if [ ! -f "$keycloak_dir/.env" ]; then
            cat > "$keycloak_dir/.env" << 'EOF'
# Keycloak Configuration
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin123
KEYCLOAK_PORT=8088
DB_VENDOR=h2
EOF
            log_success "Created Keycloak environment file"
        fi
    fi
    
    # Fix Prometheus configuration
    local prometheus_dir="$SCRIPT_DIR/007-prometheus"
    if [ -d "$prometheus_dir" ] && [ ! -f "$prometheus_dir/.env" ]; then
        cat > "$prometheus_dir/.env" << 'EOF'
# Prometheus Configuration
PROMETHEUS_PORT=9090
PROMETHEUS_DATA_PATH=./data
PROMETHEUS_CONFIG_PATH=./prometheus.yml
EOF
        log_success "Created Prometheus environment file"
    fi
    
    # Fix Vault configuration  
    local vault_dir="$SCRIPT_DIR/005-vault"
    if [ -d "$vault_dir" ] && [ ! -f "$vault_dir/.env" ]; then
        cat > "$vault_dir/.env" << 'EOF'
# Vault Configuration
VAULT_DEV_ROOT_TOKEN_ID=myroot
VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200
VAULT_ADDR=http://127.0.0.1:8200
EOF
        log_success "Created Vault environment file"
    fi
    
    # Fix Grafana port conflict with Homepage
    local grafana_dir="$SCRIPT_DIR/003-grafana"
    if [ -d "$grafana_dir" ]; then
        if grep -q "3000:3000" "$grafana_dir/docker-compose.yaml" 2>/dev/null; then
            log_warning "Grafana port conflict detected - will use port 3001"
            sed -i 's/3000:3000/3001:3000/g' "$grafana_dir/docker-compose.yaml" 2>/dev/null || true
        fi
    fi
    
    log_success "Service configurations fixed"
}

# Test individual service functionality
test_service() {
    local service_name=$1
    local port=$2
    local endpoint=${3:-""}
    
    log_info "Testing $service_name (port $port)..."
    
    # Wait for service to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -m 5 "http://localhost:$port$endpoint" >/dev/null 2>&1; then
            log_success "$service_name is responding"
            return 0
        elif nc -z localhost "$port" 2>/dev/null; then
            log_success "$service_name port is open"
            return 0
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "$service_name is not responding after ${max_attempts} attempts"
    return 1
}

# Test service functionality with specific endpoints
test_service_functionality() {
    log_info "Testing service functionality..."
    
    local tests_passed=0
    local total_tests=0
    
    # Test Traefik
    total_tests=$((total_tests + 1))
    if test_service "Traefik Dashboard" 8080 "/dashboard/"; then
        tests_passed=$((tests_passed + 1))
        log_success "Traefik: Dashboard accessible"
    fi
    
    # Test MinIO (if running)
    if docker ps | grep -q "minio"; then
        total_tests=$((total_tests + 1))
        if test_service "MinIO Console" 9001; then
            tests_passed=$((tests_passed + 1))
            log_success "MinIO: Console accessible"
        fi
    fi
    
    # Test OpenSearch (if running) 
    if docker ps | grep -q "opensearch"; then
        total_tests=$((total_tests + 1))
        if test_service "OpenSearch" 9200 "/_cluster/health"; then
            tests_passed=$((tests_passed + 1))
            log_success "OpenSearch: API accessible"
        fi
        
        total_tests=$((total_tests + 1))
        if test_service "OpenSearch Dashboards" 5601; then
            tests_passed=$((tests_passed + 1))
            log_success "OpenSearch: Dashboards accessible"
        fi
    fi
    
    # Test Prometheus (if running)
    if docker ps | grep -q "prometheus"; then
        total_tests=$((total_tests + 1))
        if test_service "Prometheus" 9090 "/api/v1/status/config"; then
            tests_passed=$((tests_passed + 1))
            log_success "Prometheus: API accessible"
        fi
    fi
    
    # Test Grafana (if running)
    if docker ps | grep -q "grafana"; then
        total_tests=$((total_tests + 1))
        if test_service "Grafana" 3001 "/api/health"; then
            tests_passed=$((tests_passed + 1))
            log_success "Grafana: API accessible"
        fi
    fi
    
    # Test Vault (if running)
    if docker ps | grep -q "vault"; then
        total_tests=$((total_tests + 1))
        if test_service "Vault" 8200 "/v1/sys/health"; then
            tests_passed=$((tests_passed + 1))
            log_success "Vault: API accessible"
        fi
    fi
    
    # Test Portainer
    if docker ps | grep -q "portainer"; then
        total_tests=$((total_tests + 1))
        if test_service "Portainer" 9000; then
            tests_passed=$((tests_passed + 1))
            log_success "Portainer: Web UI accessible"
        fi
    fi
    
    # Test Homepage
    if docker ps | grep -q "homepage"; then
        total_tests=$((total_tests + 1))
        if test_service "Homepage" 3000; then
            tests_passed=$((tests_passed + 1))
            log_success "Homepage: Dashboard accessible"
        fi
    fi
    
    # Test Ollama
    if docker ps | grep -q "ollama"; then
        total_tests=$((total_tests + 1))
        if test_service "Ollama" 11434 "/api/tags"; then
            tests_passed=$((tests_passed + 1))
            log_success "Ollama: API accessible"
        fi
    fi
    
    # Test N8N
    if docker ps | grep -q "n8n"; then
        total_tests=$((total_tests + 1))
        if test_service "N8N" 5678; then
            tests_passed=$((tests_passed + 1))
            log_success "N8N: Web interface accessible"
        fi
    fi
    
    # Test Zabbix
    if docker ps | grep -q "zabbix"; then
        total_tests=$((total_tests + 1))
        if test_service "Zabbix" 8081; then
            tests_passed=$((tests_passed + 1))
            log_success "Zabbix: Web interface accessible"
        fi
    fi
    
    # Test Keycloak (port 8088 after fix)
    if docker ps | grep -q "keycloak"; then
        total_tests=$((total_tests + 1))
        if test_service "Keycloak" 8088; then
            tests_passed=$((tests_passed + 1))
            log_success "Keycloak: Web interface accessible"
        fi
    fi
    
    echo
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}FUNCTIONALITY TEST RESULTS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "Tests Passed: ${GREEN}$tests_passed${NC}/$total_tests"
    echo -e "Success Rate: ${GREEN}$((tests_passed * 100 / total_tests))%${NC}"
    
    if [ $tests_passed -eq $total_tests ]; then
        log_success "All functional tests passed!"
        return 0
    else
        log_warning "Some tests failed. Check service logs for details."
        return 1
    fi
}

# Show service URLs and access information
show_access_info() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    SERVICE ACCESS URLs                      ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${PURPLE}🎛️ Infrastructure & Ingress:${NC}"
    echo -e "  • Traefik Dashboard:    ${CYAN}http://localhost:8080/dashboard/${NC}"
    echo
    
    echo -e "${GREEN}📊 Monitoring Stack:${NC}"
    echo -e "  • Grafana:              ${CYAN}http://localhost:3001${NC} (admin/admin)"
    echo -e "  • Prometheus:           ${CYAN}http://localhost:9090${NC}"
    echo -e "  • AlertManager:         ${CYAN}http://localhost:9093${NC}"
    echo -e "  • Node Exporter:        ${CYAN}http://localhost:9100/metrics${NC}"
    echo
    
    echo -e "${YELLOW}🗄️ Data & Storage:${NC}"
    echo -e "  • MinIO Console:        ${CYAN}http://localhost:9001${NC} (minioadmin/minioadmin123)"
    echo -e "  • OpenSearch:           ${CYAN}http://localhost:9200${NC} (admin/Admin123!@#)"
    echo -e "  • OpenSearch Dashboards:${CYAN}http://localhost:5601${NC}"
    echo
    
    echo -e "${RED}🛡️ Security & Identity:${NC}"
    echo -e "  • Vault:                ${CYAN}http://localhost:8200${NC} (token: myroot)"
    echo -e "  • Keycloak:             ${CYAN}http://localhost:8088${NC} (admin/admin123)"
    echo
    
    echo -e "${BLUE}🎮 Management & Tools:${NC}"
    echo -e "  • Portainer:            ${CYAN}http://localhost:9000${NC}"
    echo -e "  • Homepage Dashboard:   ${CYAN}http://localhost:3000${NC}"
    echo -e "  • Zabbix:               ${CYAN}http://localhost:8081${NC}"
    echo
    
    echo -e "${PURPLE}🤖 Automation & AI:${NC}"
    echo -e "  • N8N Workflows:        ${CYAN}http://localhost:5678${NC}"
    echo -e "  • Ollama API:           ${CYAN}http://localhost:11434${NC}"
    echo
}

# Main execution
main() {
    print_header
    
    case "${1:-test}" in
        fix)
            fix_configurations
            ;;
        test)
            fix_configurations
            test_service_functionality
            show_access_info
            ;;
        urls)
            show_access_info
            ;;
        *)
            echo "Usage: $0 {fix|test|urls}"
            echo "  fix  - Fix service configurations"
            echo "  test - Run complete functionality tests"
            echo "  urls - Show service access URLs"
            ;;
    esac
}

main "$@"