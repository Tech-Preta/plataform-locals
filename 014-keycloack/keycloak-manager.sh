#!/bin/bash

# ==============================================================================
# KEYCLOAK MANAGEMENT SCRIPT
# ==============================================================================
# Este script fornece comandos úteis para gerenciar o Keycloak e PostgreSQL
# 
# Uso: ./keycloak-manager.sh [COMANDO] [ARGUMENTOS]
#
# Autor: Sistema de Plataforma Local
# Versão: 1.0.0
# ==============================================================================

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Configurações
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yaml"
readonly ENV_FILE="${SCRIPT_DIR}/.env"
readonly BACKUP_DIR="${SCRIPT_DIR}/backups"
readonly LOG_FILE="${SCRIPT_DIR}/keycloak-manager.log"

# Serviços
readonly SERVICES=("keycloak-db" "keycloak")
readonly DB_SERVICE="keycloak-db"
readonly KEYCLOAK_SERVICE="keycloak"

# ==============================================================================
# FUNÇÕES UTILITÁRIAS
# ==============================================================================

# Função para logging
log() {
    echo -e "${WHITE}[$(date +'%Y-%m-%d %H:%M:%S')] $*${NC}" | tee -a "$LOG_FILE"
}

# Função para logging de erro
log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*${NC}" | tee -a "$LOG_FILE" >&2
}

# Função para logging de sucesso
log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $*${NC}" | tee -a "$LOG_FILE"
}

# Função para logging de warning
log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*${NC}" | tee -a "$LOG_FILE"
}

# Função para logging de info
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*${NC}" | tee -a "$LOG_FILE"
}

# Verificar se docker-compose está disponível
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose não encontrado. Instale o Docker Compose."
        exit 1
    fi
}

# Verificar se arquivo compose existe
check_compose_file() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "Arquivo docker-compose.yaml não encontrado em: $COMPOSE_FILE"
        exit 1
    fi
}

# Criar diretório de backup se não existir
ensure_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Diretório de backup criado: $BACKUP_DIR"
    fi
}

# Verificar se serviço está rodando
is_service_running() {
    local service=$1
    docker-compose -f "$COMPOSE_FILE" ps -q "$service" | grep -q .
}

# Aguardar serviço estar pronto
wait_for_service() {
    local service=$1
    local timeout=${2:-60}
    local count=0
    
    log_info "Aguardando $service estar pronto..."
    
    while [[ $count -lt $timeout ]]; do
        if docker-compose -f "$COMPOSE_FILE" exec -T "$service" echo "ready" &>/dev/null; then
            log_success "$service está pronto!"
            return 0
        fi
        sleep 2
        ((count += 2))
    done
    
    log_error "$service não ficou pronto em ${timeout}s"
    return 1
}

# ==============================================================================
# COMANDOS PRINCIPAIS
# ==============================================================================

# Mostrar ajuda
show_help() {
    cat << EOF
${WHITE}KEYCLOAK MANAGEMENT SCRIPT${NC}

${YELLOW}USO:${NC}
    $0 [COMANDO] [ARGUMENTOS]

${YELLOW}COMANDOS PRINCIPAIS:${NC}
    ${GREEN}start${NC}           Iniciar todos os serviços
    ${GREEN}stop${NC}            Parar todos os serviços
    ${GREEN}restart${NC}         Reiniciar todos os serviços
    ${GREEN}status${NC}          Mostrar status dos serviços
    ${GREEN}logs${NC}            Mostrar logs dos serviços
    ${GREEN}ps${NC}              Listar containers

${YELLOW}COMANDOS DE SERVIÇO:${NC}
    ${GREEN}start-db${NC}        Iniciar apenas PostgreSQL
    ${GREEN}start-keycloak${NC}  Iniciar apenas Keycloak
    ${GREEN}stop-db${NC}         Parar apenas PostgreSQL
    ${GREEN}stop-keycloak${NC}   Parar apenas Keycloak
    ${GREEN}restart-db${NC}      Reiniciar PostgreSQL
    ${GREEN}restart-keycloak${NC} Reiniciar Keycloak

${YELLOW}COMANDOS DE BACKUP/RESTORE:${NC}
    ${GREEN}backup${NC}          Criar backup do banco de dados
    ${GREEN}restore${NC} FILE    Restaurar backup do banco
    ${GREEN}list-backups${NC}    Listar backups disponíveis
    ${GREEN}cleanup-backups${NC} Limpar backups antigos

${YELLOW}COMANDOS DE ADMINISTRAÇÃO:${NC}
    ${GREEN}shell${NC}           Abrir shell no container Keycloak
    ${GREEN}db-shell${NC}        Abrir shell no PostgreSQL
    ${GREEN}db-console${NC}      Conectar ao console do PostgreSQL
    ${GREEN}export-realm${NC} REALM Export de realm
    ${GREEN}import-realm${NC} FILE  Import de realm

${YELLOW}COMANDOS DE MONITORAMENTO:${NC}
    ${GREEN}health${NC}          Verificar health dos serviços
    ${GREEN}metrics${NC}         Mostrar métricas do Keycloak
    ${GREEN}stats${NC}           Mostrar estatísticas dos containers
    ${GREEN}top${NC}             Mostrar processos dos containers

${YELLOW}COMANDOS DE LIMPEZA:${NC}
    ${GREEN}clean${NC}           Remover containers parados
    ${GREEN}reset${NC}           Reset completo (REMOVE TODOS OS DADOS!)
    ${GREEN}prune${NC}           Limpeza geral do Docker

${YELLOW}COMANDOS DE CONFIGURAÇÃO:${NC}
    ${GREEN}setup${NC}           Configuração inicial
    ${GREEN}update${NC}          Atualizar imagens
    ${GREEN}config${NC}          Mostrar configuração atual

${YELLOW}EXEMPLOS:${NC}
    $0 start                    # Iniciar todos os serviços
    $0 logs keycloak           # Ver logs do Keycloak
    $0 backup                  # Criar backup
    $0 restore backup.sql      # Restaurar backup
    $0 export-realm master     # Exportar realm master

${YELLOW}ARQUIVOS:${NC}
    Config: ${COMPOSE_FILE}
    Env:    ${ENV_FILE}
    Logs:   ${LOG_FILE}
    Backup: ${BACKUP_DIR}/

EOF
}

# Iniciar serviços
start_services() {
    log_info "Iniciando serviços Keycloak..."
    check_compose_file
    
    if [[ -f "$ENV_FILE" ]]; then
        log_info "Usando arquivo .env: $ENV_FILE"
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    else
        log_warning "Arquivo .env não encontrado, usando valores padrão"
        docker-compose -f "$COMPOSE_FILE" up -d
    fi
    
    log_success "Serviços iniciados!"
    
    # Aguardar serviços ficarem prontos
    wait_for_service "$DB_SERVICE" 60
    wait_for_service "$KEYCLOAK_SERVICE" 120
    
    show_service_urls
}

# Parar serviços
stop_services() {
    log_info "Parando serviços Keycloak..."
    docker-compose -f "$COMPOSE_FILE" down
    log_success "Serviços parados!"
}

# Reiniciar serviços
restart_services() {
    log_info "Reiniciando serviços Keycloak..."
    stop_services
    sleep 3
    start_services
}

# Status dos serviços
show_status() {
    log_info "Status dos serviços:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo
    log_info "Health status:"
    for service in "${SERVICES[@]}"; do
        if is_service_running "$service"; then
            local health=$(docker-compose -f "$COMPOSE_FILE" ps -q "$service" | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
            echo -e "  ${service}: ${GREEN}running${NC} (health: $health)"
        else
            echo -e "  ${service}: ${RED}stopped${NC}"
        fi
    done
}

# Mostrar logs
show_logs() {
    local service=${1:-}
    local lines=${2:-100}
    
    if [[ -n "$service" ]]; then
        log_info "Logs do serviço: $service"
        docker-compose -f "$COMPOSE_FILE" logs --tail="$lines" -f "$service"
    else
        log_info "Logs de todos os serviços:"
        docker-compose -f "$COMPOSE_FILE" logs --tail="$lines" -f
    fi
}

# Mostrar URLs dos serviços
show_service_urls() {
    echo
    log_success "Serviços disponíveis:"
    echo -e "  ${CYAN}Keycloak Admin Console:${NC} http://localhost:8080/admin"
    echo -e "  ${CYAN}Keycloak Account Console:${NC} http://localhost:8080/realms/master/account"
    echo -e "  ${CYAN}Keycloak Health:${NC} http://localhost:8080/health"
    echo -e "  ${CYAN}Keycloak Metrics:${NC} http://localhost:8080/metrics"
    echo -e "  ${CYAN}PostgreSQL:${NC} localhost:5432"
    echo
    echo -e "  ${YELLOW}Admin User:${NC} admin"
    echo -e "  ${YELLOW}Admin Password:${NC} admin_password_change_this"
    echo
}

# ==============================================================================
# COMANDOS DE BACKUP/RESTORE
# ==============================================================================

# Criar backup
create_backup() {
    ensure_backup_dir
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${BACKUP_DIR}/keycloak_backup_${timestamp}.sql"
    
    log_info "Criando backup do banco de dados..."
    
    if ! is_service_running "$DB_SERVICE"; then
        log_error "Serviço de banco não está rodando"
        return 1
    fi
    
    # Backup do PostgreSQL
    docker-compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" pg_dump -U keycloak keycloak > "$backup_file"
    
    if [[ -f "$backup_file" && -s "$backup_file" ]]; then
        log_success "Backup criado: $backup_file"
        
        # Comprimir backup
        gzip "$backup_file"
        log_success "Backup comprimido: ${backup_file}.gz"
        
        # Mostrar tamanho
        local size=$(du -h "${backup_file}.gz" | cut -f1)
        log_info "Tamanho do backup: $size"
    else
        log_error "Falha ao criar backup"
        return 1
    fi
}

# Restaurar backup
restore_backup() {
    local backup_file=$1
    
    if [[ -z "$backup_file" ]]; then
        log_error "Especifique o arquivo de backup"
        echo "Uso: $0 restore <arquivo_backup>"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        # Tentar encontrar no diretório de backup
        local full_path="${BACKUP_DIR}/$backup_file"
        if [[ -f "$full_path" ]]; then
            backup_file="$full_path"
        else
            log_error "Arquivo de backup não encontrado: $backup_file"
            return 1
        fi
    fi
    
    log_warning "ATENÇÃO: Esta operação irá sobrescrever o banco atual!"
    read -p "Continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operação cancelada"
        return 0
    fi
    
    log_info "Restaurando backup: $backup_file"
    
    if ! is_service_running "$DB_SERVICE"; then
        log_error "Serviço de banco não está rodando"
        return 1
    fi
    
    # Descomprimir se necessário
    local sql_file="$backup_file"
    if [[ "$backup_file" == *.gz ]]; then
        sql_file="${backup_file%.gz}"
        gunzip -c "$backup_file" > "$sql_file"
    fi
    
    # Restaurar banco
    docker-compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" psql -U keycloak keycloak < "$sql_file"
    
    # Limpar arquivo temporário se foi descomprimido
    if [[ "$backup_file" == *.gz && -f "$sql_file" ]]; then
        rm -f "$sql_file"
    fi
    
    log_success "Backup restaurado com sucesso!"
    log_info "Reinicie o Keycloak para aplicar as mudanças"
}

# Listar backups
list_backups() {
    ensure_backup_dir
    
    log_info "Backups disponíveis em $BACKUP_DIR:"
    
    if [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        ls -lah "$BACKUP_DIR"/*.sql* 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        log_warning "Nenhum backup encontrado"
    fi
}

# Limpeza de backups antigos
cleanup_backups() {
    local days=${1:-7}
    ensure_backup_dir
    
    log_info "Removendo backups com mais de $days dias..."
    
    local count=$(find "$BACKUP_DIR" -name "keycloak_backup_*.sql*" -mtime +$days | wc -l)
    
    if [[ $count -gt 0 ]]; then
        find "$BACKUP_DIR" -name "keycloak_backup_*.sql*" -mtime +$days -delete
        log_success "Removidos $count backups antigos"
    else
        log_info "Nenhum backup antigo para remover"
    fi
}

# ==============================================================================
# COMANDOS DE ADMINISTRAÇÃO
# ==============================================================================

# Shell no container Keycloak
keycloak_shell() {
    log_info "Abrindo shell no container Keycloak..."
    docker-compose -f "$COMPOSE_FILE" exec "$KEYCLOAK_SERVICE" /bin/bash
}

# Shell no container PostgreSQL
db_shell() {
    log_info "Abrindo shell no container PostgreSQL..."
    docker-compose -f "$COMPOSE_FILE" exec "$DB_SERVICE" /bin/bash
}

# Console do PostgreSQL
db_console() {
    log_info "Conectando ao console PostgreSQL..."
    docker-compose -f "$COMPOSE_FILE" exec "$DB_SERVICE" psql -U keycloak keycloak
}

# Exportar realm
export_realm() {
    local realm=${1:-}
    
    if [[ -z "$realm" ]]; then
        log_error "Especifique o nome do realm"
        echo "Uso: $0 export-realm <nome_do_realm>"
        return 1
    fi
    
    ensure_backup_dir
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local export_file="${BACKUP_DIR}/realm_${realm}_${timestamp}.json"
    
    log_info "Exportando realm: $realm"
    
    docker-compose -f "$COMPOSE_FILE" exec "$KEYCLOAK_SERVICE" /opt/keycloak/bin/kc.sh export \
        --realm "$realm" \
        --file "/tmp/realm_export.json"
    
    docker-compose -f "$COMPOSE_FILE" cp "${KEYCLOAK_SERVICE}:/tmp/realm_export.json" "$export_file"
    
    if [[ -f "$export_file" ]]; then
        log_success "Realm exportado: $export_file"
    else
        log_error "Falha ao exportar realm"
        return 1
    fi
}

# Importar realm
import_realm() {
    local realm_file=$1
    
    if [[ -z "$realm_file" ]]; then
        log_error "Especifique o arquivo do realm"
        echo "Uso: $0 import-realm <arquivo_realm.json>"
        return 1
    fi
    
    if [[ ! -f "$realm_file" ]]; then
        log_error "Arquivo não encontrado: $realm_file"
        return 1
    fi
    
    log_info "Importando realm: $realm_file"
    
    # Copiar arquivo para container
    docker-compose -f "$COMPOSE_FILE" cp "$realm_file" "${KEYCLOAK_SERVICE}:/tmp/realm_import.json"
    
    # Importar realm
    docker-compose -f "$COMPOSE_FILE" exec "$KEYCLOAK_SERVICE" /opt/keycloak/bin/kc.sh import \
        --file "/tmp/realm_import.json"
    
    log_success "Realm importado com sucesso!"
}

# ==============================================================================
# COMANDOS DE MONITORAMENTO
# ==============================================================================

# Verificar health
check_health() {
    log_info "Verificando health dos serviços..."
    
    # Health do Keycloak
    if is_service_running "$KEYCLOAK_SERVICE"; then
        local health_url="http://localhost:8080/health"
        if curl -s -f "$health_url" > /dev/null; then
            log_success "Keycloak health: OK"
            curl -s "$health_url" | jq . 2>/dev/null || curl -s "$health_url"
        else
            log_error "Keycloak health: FAIL"
        fi
    else
        log_warning "Keycloak não está rodando"
    fi
    
    echo
    
    # Health do PostgreSQL
    if is_service_running "$DB_SERVICE"; then
        if docker-compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" pg_isready -U keycloak > /dev/null; then
            log_success "PostgreSQL health: OK"
        else
            log_error "PostgreSQL health: FAIL"
        fi
    else
        log_warning "PostgreSQL não está rodando"
    fi
}

# Mostrar métricas
show_metrics() {
    log_info "Métricas do Keycloak:"
    
    if is_service_running "$KEYCLOAK_SERVICE"; then
        local metrics_url="http://localhost:8080/metrics"
        if curl -s -f "$metrics_url" > /dev/null; then
            curl -s "$metrics_url"
        else
            log_error "Métricas não disponíveis"
        fi
    else
        log_warning "Keycloak não está rodando"
    fi
}

# Estatísticas dos containers
show_stats() {
    log_info "Estatísticas dos containers:"
    docker-compose -f "$COMPOSE_FILE" ps -q | xargs docker stats --no-stream
}

# Processos dos containers
show_top() {
    log_info "Processos dos containers:"
    for service in "${SERVICES[@]}"; do
        if is_service_running "$service"; then
            echo -e "\n${CYAN}=== $service ===${NC}"
            docker-compose -f "$COMPOSE_FILE" top "$service"
        fi
    done
}

# ==============================================================================
# COMANDOS DE LIMPEZA
# ==============================================================================

# Limpeza básica
clean_containers() {
    log_info "Removendo containers parados..."
    docker-compose -f "$COMPOSE_FILE" rm -f
    log_success "Containers parados removidos"
}

# Reset completo
reset_all() {
    log_warning "ATENÇÃO: Esta operação irá remover TODOS os dados!"
    echo "Isso inclui:"
    echo "  - Todos os containers"
    echo "  - Todos os volumes de dados"
    echo "  - Configurações e usuários do Keycloak"
    echo "  - Dados do banco PostgreSQL"
    echo
    read -p "Tem CERTEZA que deseja continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operação cancelada"
        return 0
    fi
    
    log_info "Executando reset completo..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    docker-compose -f "$COMPOSE_FILE" rm -f
    
    log_success "Reset completo executado!"
    log_info "Execute '$0 start' para recriar os serviços"
}

# Limpeza geral do Docker
prune_docker() {
    log_info "Executando limpeza geral do Docker..."
    docker system prune -f
    log_success "Limpeza geral concluída"
}

# ==============================================================================
# COMANDOS DE CONFIGURAÇÃO
# ==============================================================================

# Configuração inicial
setup_initial() {
    log_info "Executando configuração inicial..."
    
    # Verificar dependências
    check_docker_compose
    check_compose_file
    
    # Criar arquivo .env se não existir
    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "${ENV_FILE}.example" ]]; then
            cp "${ENV_FILE}.example" "$ENV_FILE"
            log_success "Arquivo .env criado a partir do exemplo"
            log_warning "EDITE o arquivo .env antes de iniciar os serviços!"
        else
            log_warning "Arquivo .env.example não encontrado"
        fi
    fi
    
    # Criar diretórios necessários
    ensure_backup_dir
    
    log_success "Configuração inicial concluída!"
    log_info "Próximos passos:"
    echo "  1. Edite o arquivo .env com suas configurações"
    echo "  2. Execute: $0 start"
    echo "  3. Acesse: http://localhost:8080/admin"
}

# Atualizar imagens
update_images() {
    log_info "Atualizando imagens Docker..."
    docker-compose -f "$COMPOSE_FILE" pull
    log_success "Imagens atualizadas!"
    log_info "Execute '$0 restart' para aplicar as atualizações"
}

# Mostrar configuração atual
show_config() {
    log_info "Configuração atual:"
    echo
    echo -e "${CYAN}Arquivo Compose:${NC} $COMPOSE_FILE"
    echo -e "${CYAN}Arquivo Env:${NC} $ENV_FILE"
    echo -e "${CYAN}Diretório Backup:${NC} $BACKUP_DIR"
    echo -e "${CYAN}Log File:${NC} $LOG_FILE"
    echo
    
    if [[ -f "$ENV_FILE" ]]; then
        echo -e "${CYAN}Variáveis de ambiente principais:${NC}"
        grep -E "^[A-Z_]+=" "$ENV_FILE" | head -10
        echo "..."
    else
        log_warning "Arquivo .env não encontrado"
    fi
    
    echo
    docker-compose -f "$COMPOSE_FILE" config --services
}

# ==============================================================================
# FUNÇÃO PRINCIPAL
# ==============================================================================

main() {
    local command=${1:-}
    
    # Criar log file se não existir
    touch "$LOG_FILE"
    
    case "$command" in
        # Comandos principais
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "${2:-}" "${3:-100}"
            ;;
        "ps")
            docker-compose -f "$COMPOSE_FILE" ps
            ;;
            
        # Comandos de serviço específico
        "start-db")
            docker-compose -f "$COMPOSE_FILE" up -d "$DB_SERVICE"
            ;;
        "start-keycloak")
            docker-compose -f "$COMPOSE_FILE" up -d "$KEYCLOAK_SERVICE"
            ;;
        "stop-db")
            docker-compose -f "$COMPOSE_FILE" stop "$DB_SERVICE"
            ;;
        "stop-keycloak")
            docker-compose -f "$COMPOSE_FILE" stop "$KEYCLOAK_SERVICE"
            ;;
        "restart-db")
            docker-compose -f "$COMPOSE_FILE" restart "$DB_SERVICE"
            ;;
        "restart-keycloak")
            docker-compose -f "$COMPOSE_FILE" restart "$KEYCLOAK_SERVICE"
            ;;
            
        # Comandos de backup/restore
        "backup")
            create_backup
            ;;
        "restore")
            restore_backup "$2"
            ;;
        "list-backups")
            list_backups
            ;;
        "cleanup-backups")
            cleanup_backups "${2:-7}"
            ;;
            
        # Comandos de administração
        "shell")
            keycloak_shell
            ;;
        "db-shell")
            db_shell
            ;;
        "db-console")
            db_console
            ;;
        "export-realm")
            export_realm "$2"
            ;;
        "import-realm")
            import_realm "$2"
            ;;
            
        # Comandos de monitoramento
        "health")
            check_health
            ;;
        "metrics")
            show_metrics
            ;;
        "stats")
            show_stats
            ;;
        "top")
            show_top
            ;;
            
        # Comandos de limpeza
        "clean")
            clean_containers
            ;;
        "reset")
            reset_all
            ;;
        "prune")
            prune_docker
            ;;
            
        # Comandos de configuração
        "setup")
            setup_initial
            ;;
        "update")
            update_images
            ;;
        "config")
            show_config
            ;;
            
        # Help e comandos inválidos
        "help" | "-h" | "--help" | "")
            show_help
            ;;
        *)
            log_error "Comando inválido: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal com todos os argumentos
main "$@"
