#!/bin/bash

# Script para habilitar métricas nativas do Docker daemon
# Baseado na documentação oficial do Docker + Prometheus

echo "🐳 Configurando métricas nativas do Docker daemon..."
echo "� Referência: https://docs.docker.com/config/daemon/prometheus/"

# Verificar se Docker está rodando
if ! systemctl is-active --quiet docker; then
    echo "❌ Docker não está rodando. Inicie o Docker primeiro:"
    echo "   sudo systemctl start docker"
    exit 1
fi

# Backup do arquivo existente (se houver)
if [ -f /etc/docker/daemon.json ]; then
    echo "📋 Arquivo daemon.json existente encontrado"
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup criado: /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Mostrar configuração atual
    echo "📄 Configuração atual:"
    cat /etc/docker/daemon.json | jq . 2>/dev/null || cat /etc/docker/daemon.json
else
    echo "📝 Criando novo arquivo daemon.json"
fi

# Verificar se jq está disponível para mesclar JSON
if command -v jq >/dev/null 2>&1; then
    echo "🔧 Mesclando configuração com jq..."
    
    # Se arquivo existe, mesclar configurações
    if [ -f /etc/docker/daemon.json ]; then
        # Mesclar configuração existente com metrics-addr
        sudo jq '. + {"metrics-addr": "127.0.0.1:9323"}' /etc/docker/daemon.json > /tmp/daemon_merged.json
        sudo mv /tmp/daemon_merged.json /etc/docker/daemon.json
        echo "✅ Configuração mesclada com sucesso"
    else
        # Criar nova configuração
        echo '{"metrics-addr": "127.0.0.1:9323"}' | sudo tee /etc/docker/daemon.json > /dev/null
        echo "✅ Nova configuração criada"
    fi
else
    echo "⚠️  jq não encontrado. Criando configuração básica..."
    # Configuração mínima conforme documentação oficial
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "metrics-addr": "127.0.0.1:9323"
}
EOF
fi

echo "✅ Configuração criada em /etc/docker/daemon.json"

# Mostrar configuração final
echo ""
echo "📄 Configuração final do daemon.json:"
sudo cat /etc/docker/daemon.json | jq . 2>/dev/null || sudo cat /etc/docker/daemon.json

echo ""
echo "🔄 Reiniciando Docker daemon..."
sudo systemctl restart docker

# Aguardar o Docker inicializar
echo "⏳ Aguardando Docker inicializar..."
sleep 5

# Verificar se Docker iniciou corretamente
if systemctl is-active --quiet docker; then
    echo "✅ Docker reiniciado com sucesso!"
    
    # Testar se métricas estão disponíveis
    echo "🧪 Testando endpoint de métricas..."
    if curl -s http://localhost:9323/metrics | head -n 5 >/dev/null 2>&1; then
        echo "✅ Métricas do Docker disponíveis em: http://localhost:9323/metrics"
        echo ""
        echo "📊 Primeiras linhas das métricas:"
        curl -s http://localhost:9323/metrics | head -n 10
    else
        echo "⚠️  Endpoint de métricas não está respondendo ainda."
        echo "   Aguarde alguns segundos e teste: curl http://localhost:9323/metrics"
    fi
else
    echo "❌ Erro ao reiniciar Docker!"
    echo "🔄 Tentando restaurar configuração anterior..."
    
    # Restaurar backup mais recente
    BACKUP_FILE=$(ls -t /etc/docker/daemon.json.backup* 2>/dev/null | head -n 1)
    if [ -n "$BACKUP_FILE" ]; then
        sudo mv "$BACKUP_FILE" /etc/docker/daemon.json
        sudo systemctl restart docker
        echo "✅ Configuração anterior restaurada"
    fi
    exit 1
fi

echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "1. Adicionar job 'docker-daemon' no prometheus.yml"
echo "2. Reiniciar Prometheus: docker compose restart prometheus"
echo ""
echo "📋 Job para adicionar no prometheus.yml:"
echo ""
echo "  - job_name: 'docker-daemon'"
echo "    static_configs:"
echo "      - targets: ['host.docker.internal:9323']  # Para containers"
echo "      # ou: ['localhost:9323']                   # Para host"
echo ""
echo "✅ Configuração do Docker daemon concluída!"
