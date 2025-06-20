#!/bin/bash

# Script de gerenciamento do Ollama + Open WebUI
# Facilita operações comuns como iniciar, parar, backup, etc.

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
CROSS="❌"
INFO="ℹ️"
ROBOT="🤖"

# print_header prints a formatted header identifying the Ollama and Open WebUI Manager script.
print_header() {
    echo -e "${BLUE}================================"
    echo -e "🤖 Ollama + Open WebUI Manager"
    echo -e "================================${NC}"
    echo
}

# print_usage displays usage instructions and lists all available commands for managing Ollama and Open WebUI services.
print_usage() {
    echo -e "${YELLOW}Uso: $0 [comando]${NC}"
    echo
    echo -e "${GREEN}Comandos disponíveis:${NC}"
    echo -e "  ${BLUE}start${NC}     - Iniciar os serviços"
    echo -e "  ${BLUE}stop${NC}      - Parar os serviços"
    echo -e "  ${BLUE}restart${NC}   - Reiniciar os serviços"
    echo -e "  ${BLUE}status${NC}    - Ver status dos serviços"
    echo -e "  ${BLUE}logs${NC}      - Ver logs dos serviços"
    echo -e "  ${BLUE}models${NC}    - Listar modelos instalados"
    echo -e "  ${BLUE}pull${NC}      - Baixar um modelo"
    echo -e "  ${BLUE}remove${NC}    - Remover um modelo"
    echo -e "  ${BLUE}backup${NC}    - Fazer backup dos dados"
    echo -e "  ${BLUE}restore${NC}   - Restaurar backup"
    echo -e "  ${BLUE}clean${NC}     - Limpeza completa (CUIDADO!)"
    echo -e "  ${BLUE}setup${NC}     - Configuração inicial"
    echo -e "  ${BLUE}update${NC}    - Atualizar imagens"
    echo -e "  ${BLUE}health${NC}    - Verificar saúde dos serviços"
    echo
}

# check_requirements verifies that Docker and Docker Compose are installed, exiting with an error if either is missing.
check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo -e "${CROSS} ${RED}Docker não encontrado. Instale o Docker primeiro.${NC}"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        echo -e "${CROSS} ${RED}Docker Compose não encontrado. Instale o Docker Compose primeiro.${NC}"
        exit 1
    fi
}

# start_services starts the Ollama and Open WebUI Docker services, waits for initialization, and checks their availability.
start_services() {
    echo -e "${ROCKET} ${GREEN}Iniciando Ollama + Open WebUI...${NC}"
    docker compose up -d
    
    echo -e "${INFO} ${BLUE}Aguardando serviços iniciarem...${NC}"
    sleep 10
    
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1 && \
       curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}Serviços iniciados com sucesso!${NC}"
        echo -e "${INFO} ${BLUE}Ollama API: http://localhost:11434${NC}"
        echo -e "${INFO} ${BLUE}Open WebUI: http://localhost:3000${NC}"
    else
        echo -e "${WARNING} ${YELLOW}Serviços podem estar iniciando ainda. Verifique com '$(basename $0) status'${NC}"
    fi
}

# stop_services stops all running Docker Compose services for Ollama and Open WebUI.
stop_services() {
    echo -e "${INFO} ${BLUE}Parando serviços...${NC}"
    docker compose down
    echo -e "${CHECK} ${GREEN}Serviços parados.${NC}"
}

# restart_services restarts all Docker Compose services for Ollama and Open WebUI.
restart_services() {
    echo -e "${INFO} ${BLUE}Reiniciando serviços...${NC}"
    docker compose restart
    echo -e "${CHECK} ${GREEN}Serviços reiniciados.${NC}"
}

# show_status displays the status of Docker Compose services and checks connectivity to the Ollama API and Open WebUI endpoints.
show_status() {
    echo -e "${INFO} ${BLUE}Status dos serviços:${NC}"
    docker compose ps
    
    echo
    echo -e "${INFO} ${BLUE}Verificando conectividade:${NC}"
    
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}Ollama API: Funcionando${NC}"
    else
        echo -e "${CROSS} ${RED}Ollama API: Não respondendo${NC}"
    fi
    
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}Open WebUI: Funcionando${NC}"
    else
        echo -e "${CROSS} ${RED}Open WebUI: Não respondendo${NC}"
    fi
}

# show_logs streams real-time logs from all Docker Compose services until interrupted.
show_logs() {
    echo -e "${INFO} ${BLUE}Logs dos serviços (Ctrl+C para sair):${NC}"
    docker compose logs -f
}

# list_models displays the list of installed Ollama models or provides guidance if none are found.
list_models() {
    echo -e "${ROBOT} ${BLUE}Modelos instalados:${NC}"
    if docker exec ollama ollama list 2>/dev/null; then
        echo
        echo -e "${INFO} ${BLUE}Para usar um modelo no WebUI, vá em Settings > Models${NC}"
    else
        echo -e "${WARNING} ${YELLOW}Ollama não está rodando ou não há modelos instalados.${NC}"
        echo -e "${INFO} ${BLUE}Use '$(basename $0) pull <modelo>' para baixar um modelo.${NC}"
    fi
}

# pull_model downloads a specified Ollama model inside the container, displaying usage instructions and popular models if no model name is provided, and reports the result.
pull_model() {
    if [ -z "$2" ]; then
        echo -e "${WARNING} ${YELLOW}Uso: $0 pull <nome-do-modelo>${NC}"
        echo
        echo -e "${INFO} ${BLUE}Modelos populares:${NC}"
        echo -e "  ${GREEN}llama3.2:3b${NC}     - Llama 3.2 3B (pequeno, ~2GB)"
        echo -e "  ${GREEN}llama3.2:7b${NC}     - Llama 3.2 7B (médio, ~4GB)"
        echo -e "  ${GREEN}mistral:7b${NC}      - Mistral 7B (boa qualidade, ~4GB)"
        echo -e "  ${GREEN}codellama:7b${NC}    - Code Llama 7B (para código, ~4GB)"
        echo -e "  ${GREEN}qwen2.5:3b${NC}      - Qwen 2.5 3B (eficiente, ~2GB)"
        return 1
    fi
    
    MODEL=$2
    echo -e "${ROBOT} ${BLUE}Baixando modelo: ${MODEL}...${NC}"
    docker exec ollama ollama pull "$MODEL"
    
    if [ $? -eq 0 ]; then
        echo -e "${CHECK} ${GREEN}Modelo ${MODEL} baixado com sucesso!${NC}"
        echo -e "${INFO} ${BLUE}Agora você pode usá-lo no WebUI.${NC}"
    else
        echo -e "${CROSS} ${RED}Erro ao baixar modelo ${MODEL}.${NC}"
    fi
}

# remove_model removes a specified Ollama model from the container after user confirmation. If no model name is provided, it displays usage instructions.
remove_model() {
    if [ -z "$2" ]; then
        echo -e "${WARNING} ${YELLOW}Uso: $0 remove <nome-do-modelo>${NC}"
        echo -e "${INFO} ${BLUE}Use '$(basename $0) models' para ver modelos instalados.${NC}"
        return 1
    fi
    
    MODEL=$2
    echo -e "${WARNING} ${YELLOW}Removendo modelo: ${MODEL}...${NC}"
    read -p "Tem certeza? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec ollama ollama rm "$MODEL"
        echo -e "${CHECK} ${GREEN}Modelo ${MODEL} removido.${NC}"
    else
        echo -e "${INFO} ${BLUE}Operação cancelada.${NC}"
    fi
}

# backup_data creates compressed backup archives of Ollama and Open WebUI Docker volumes in the local backups directory, naming them with a timestamp.
backup_data() {
    BACKUP_DIR="./backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    
    echo -e "${INFO} ${BLUE}Criando backup dos dados...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup Ollama
    echo -e "${INFO} ${BLUE}Backup do Ollama...${NC}"
    docker run --rm -v ollama_ollama-data:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine \
        tar czf "/backup/ollama-backup-$DATE.tar.gz" -C /source .
    
    # Backup Open WebUI
    echo -e "${INFO} ${BLUE}Backup do Open WebUI...${NC}"
    docker run --rm -v ollama_open-webui-data:/source -v "$(pwd)/$BACKUP_DIR":/backup alpine \
        tar czf "/backup/webui-backup-$DATE.tar.gz" -C /source .
    
    echo -e "${CHECK} ${GREEN}Backup concluído:${NC}"
    echo -e "  ${BLUE}Ollama: $BACKUP_DIR/ollama-backup-$DATE.tar.gz${NC}"
    echo -e "  ${BLUE}WebUI:  $BACKUP_DIR/webui-backup-$DATE.tar.gz${NC}"
}

# restore_data restores Ollama and Open WebUI data volumes from selected backup files, overwriting current data after user confirmation.
restore_data() {
    BACKUP_DIR="./backups"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${CROSS} ${RED}Diretório de backup não encontrado: $BACKUP_DIR${NC}"
        return 1
    fi
    
    echo -e "${INFO} ${BLUE}Backups disponíveis:${NC}"
    ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || {
        echo -e "${CROSS} ${RED}Nenhum backup encontrado.${NC}"
        return 1
    }
    
    echo
    read -p "Nome do arquivo de backup do Ollama: " OLLAMA_BACKUP
    read -p "Nome do arquivo de backup do WebUI: " WEBUI_BACKUP
    
    if [ ! -f "$BACKUP_DIR/$OLLAMA_BACKUP" ] || [ ! -f "$BACKUP_DIR/$WEBUI_BACKUP" ]; then
        echo -e "${CROSS} ${RED}Arquivos de backup não encontrados.${NC}"
        return 1
    fi
    
    echo -e "${WARNING} ${YELLOW}Isso irá sobrescrever os dados atuais!${NC}"
    read -p "Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_services
        
        echo -e "${INFO} ${BLUE}Restaurando Ollama...${NC}"
        docker run --rm -v ollama_ollama-data:/dest -v "$(pwd)/$BACKUP_DIR":/backup alpine \
            tar xzf "/backup/$OLLAMA_BACKUP" -C /dest
        
        echo -e "${INFO} ${BLUE}Restaurando WebUI...${NC}"
        docker run --rm -v ollama_open-webui-data:/dest -v "$(pwd)/$BACKUP_DIR":/backup alpine \
            tar xzf "/backup/$WEBUI_BACKUP" -C /dest
        
        start_services
        echo -e "${CHECK} ${GREEN}Restore concluído!${NC}"
    fi
}

# clean_all removes all Ollama and Open WebUI data, including models, conversations, and configurations, after explicit user confirmation.
clean_all() {
    echo -e "${WARNING} ${RED}ATENÇÃO: Isso irá remover TODOS os dados!${NC}"
    echo -e "${WARNING} ${RED}- Todos os modelos baixados${NC}"
    echo -e "${WARNING} ${RED}- Todas as conversas${NC}"
    echo -e "${WARNING} ${RED}- Todas as configurações${NC}"
    echo
    read -p "Tem CERTEZA ABSOLUTA? Digite 'DELETE' para confirmar: " CONFIRM
    
    if [ "$CONFIRM" = "DELETE" ]; then
        echo -e "${INFO} ${BLUE}Parando serviços...${NC}"
        docker compose down
        
        echo -e "${INFO} ${BLUE}Removendo volumes...${NC}"
        docker volume rm ollama_ollama-data ollama_open-webui-data 2>/dev/null || true
        
        echo -e "${INFO} ${BLUE}Limpando imagens não utilizadas...${NC}"
        docker system prune -f
        
        echo -e "${CHECK} ${GREEN}Limpeza completa realizada.${NC}"
        echo -e "${INFO} ${BLUE}Use '$(basename $0) start' para reiniciar do zero.${NC}"
    else
        echo -e "${INFO} ${BLUE}Operação cancelada.${NC}"
    fi
}

# initial_setup performs the initial configuration for Ollama and Open WebUI, creating a .env file, generating secret keys, and starting the services.
#
# If a .env file already exists, prompts for overwrite confirmation. Copies .env.example to .env, replaces secret placeholders with generated values, and starts the Docker services. Prints next steps for user setup.
initial_setup() {
    echo -e "${ROCKET} ${GREEN}Configuração inicial do Ollama + Open WebUI${NC}"
    
    # Verificar se já existe configuração
    if [ -f ".env" ]; then
        echo -e "${WARNING} ${YELLOW}Arquivo .env já existe.${NC}"
        read -p "Sobrescrever? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
    fi
    
    # Copiar arquivo de exemplo
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${CHECK} ${GREEN}Arquivo .env criado a partir do exemplo.${NC}"
        
        # Gerar chaves secretas
        SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || echo "change-this-secret-key-$(date +%s)")
        JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "change-this-jwt-secret-$(date +%s)")
        
        # Substituir chaves no arquivo
        sed -i "s/sua-chave-secreta-mude-isso-agora-por-favor/$SECRET_KEY/" .env
        sed -i "s/sua-jwt-secret-mude-isso-tambem-agora/$JWT_SECRET/" .env
        
        echo -e "${CHECK} ${GREEN}Chaves secretas geradas automaticamente.${NC}"
    fi
    
    # Iniciar serviços
    echo -e "${INFO} ${BLUE}Iniciando serviços...${NC}"
    start_services
    
    echo
    echo -e "${CHECK} ${GREEN}Configuração inicial concluída!${NC}"
    echo
    echo -e "${INFO} ${BLUE}Próximos passos:${NC}"
    echo -e "1. Acesse http://localhost:3000"
    echo -e "2. Crie sua conta (primeiro usuário será admin)"
    echo -e "3. Baixe um modelo: $(basename $0) pull llama3.2:3b"
    echo -e "4. Comece a conversar!"
}

# update_images pulls the latest Docker images for all services and restarts them.
update_images() {
    echo -e "${INFO} ${BLUE}Atualizando imagens Docker...${NC}"
    docker compose pull
    docker compose up -d
    echo -e "${CHECK} ${GREEN}Imagens atualizadas!${NC}"
}

# health_check displays the status and health of Ollama and Open WebUI Docker services, including container status, API connectivity, installed model count, resource usage, and disk space.
health_check() {
    echo -e "${INFO} ${BLUE}Verificando saúde dos serviços...${NC}"
    
    # Verificar containers
    echo -e "\n${BLUE}Status dos containers:${NC}"
    docker compose ps
    
    # Verificar APIs
    echo -e "\n${BLUE}Teste de conectividade:${NC}"
    
    # Ollama API
    if curl -s -m 5 http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}Ollama API: Respondendo${NC}"
        
        # Ver modelos
        MODELS=$(docker exec ollama ollama list 2>/dev/null | grep -v "NAME" | wc -l)
        echo -e "  ${INFO} Modelos instalados: $MODELS"
    else
        echo -e "${CROSS} ${RED}Ollama API: Não respondendo${NC}"
    fi
    
    # Open WebUI
    if curl -s -m 5 http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}Open WebUI: Respondendo${NC}"
    else
        echo -e "${CROSS} ${RED}Open WebUI: Não respondendo${NC}"
    fi
    
    # Verificar recursos
    echo -e "\n${BLUE}Uso de recursos:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    # Verificar volumes
    echo -e "\n${BLUE}Espaço em disco:${NC}"
    docker system df
}

# main parses the first command-line argument and dispatches the corresponding Ollama/Open WebUI management command.
main() {
    check_requirements
    
    case "${1:-help}" in
        start)
            print_header
            start_services
            ;;
        stop)
            print_header
            stop_services
            ;;
        restart)
            print_header
            restart_services
            ;;
        status)
            print_header
            show_status
            ;;
        logs)
            print_header
            show_logs
            ;;
        models)
            print_header
            list_models
            ;;
        pull)
            print_header
            pull_model "$@"
            ;;
        remove|rm)
            print_header
            remove_model "$@"
            ;;
        backup)
            print_header
            backup_data
            ;;
        restore)
            print_header
            restore_data
            ;;
        clean)
            print_header
            clean_all
            ;;
        setup)
            print_header
            initial_setup
            ;;
        update)
            print_header
            update_images
            ;;
        health)
            print_header
            health_check
            ;;
        help|--help|-h)
            print_header
            print_usage
            ;;
        *)
            print_header
            echo -e "${CROSS} ${RED}Comando inválido: $1${NC}"
            echo
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
