# ✅ Configuração Concluída - Prometheus & Alertmanager

## 🎯 Resumo das Configurações Realizadas

### 📊 **Prometheus** (`007-prometheus/`)
- ✅ **prometheus.yml**: Configuração otimizada com todos os targets
- ✅ **docker-compose.yaml**: Stack completo com 4 serviços integrados
- ✅ **rules/**: Regras de alerta categorizadas e otimizadas
- ✅ **webhook-test.py**: Servidor de teste para alertas
- ✅ **README.md**: Documentação completa e detalhada

### 🚨 **Alertmanager** (`004-alertmanager/`)
- ✅ **alertmanager.yml**: Configuração avançada com roteamento inteligente
- ✅ **docker-compose.yaml**: Serviço configurado e integrado
- ✅ **email-config-examples.md**: Exemplos de configuração de email

---

## 🚀 Como Usar

### 1. **Iniciar o stack de monitoramento**
```bash
cd 007-prometheus
docker compose up -d
```

### 2. **Verificar se todos os serviços estão funcionando**
```bash
docker compose ps
```

### 3. **Iniciar servidor de teste para alertas (opcional)**
```bash
# Em outro terminal
python3 webhook-test.py
```

### 4. **Acessar as interfaces**
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093  
- **Node Exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080
- **Webhook Test**: http://localhost:5001

---

## 📊 Componentes do Stack

| Serviço           | Porta | Função                             |
| ----------------- | ----- | ---------------------------------- |
| **Prometheus**    | 9090  | Coleta e armazenamento de métricas |
| **Alertmanager**  | 9093  | Gerenciamento e envio de alertas   |
| **Node Exporter** | 9100  | Métricas do sistema host           |
| **cAdvisor**      | 8080  | Métricas de containers Docker      |

---

## 🎯 Targets Monitorados

- ✅ **prometheus**: Auto-monitoramento do Prometheus
- ✅ **alertmanager**: Status e métricas do Alertmanager
- ✅ **node-exporter**: CPU, memória, disco, rede do host
- ✅ **cadvisor**: Métricas de todos os containers Docker
- ✅ **docker-containers**: Autodiscovery de containers
- ✅ **vault**: Métricas do HashiCorp Vault (se executando)

---

## 🚨 Sistema de Alertas Configurado

### 📋 **Categorias de Alertas**

#### 🖥️ **Sistema (Node Exporter)**
- CPU usage (warning: >85%, critical: >95%)
- Memory usage (warning: >80%, critical: >90%)  
- Disk space (warning: <20%, critical: <10%)
- Node offline detection

#### 🐳 **Containers (cAdvisor)**
- Container down detection
- High memory usage (warning: >85%, critical: >95%)
- High CPU usage (warning: >80%)
- Container restart frequency monitoring

#### 📊 **Monitoramento (Self-monitoring)**
- Prometheus target down
- Configuration reload failures
- Alertmanager offline detection
- Rule evaluation failures

### 🎯 **Receivers/Notificações**
- **default-receiver**: Alertas gerais → webhook
- **critical-alerts**: Alertas críticos → webhook prioritário
- **system-alerts**: Alertas de sistema → webhook específico
- **docker-alerts**: Alertas de containers → webhook específico
- **monitoring-alerts**: Alertas do stack → webhook específico

---

## 🧪 Testando o Sistema

### 1. **Testar com webhook server**
```bash
# Terminal 1: Webhook server
python3 webhook-test.py

# Terminal 2: Gerar carga de CPU
stress --cpu 8 --timeout 300s

# Verificar alertas em: http://localhost:5001
```

### 2. **Verificar targets no Prometheus**
```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].labels'
```

### 3. **Verificar alertas ativos**
```bash
curl -s http://localhost:9093/api/v1/alerts | jq '.data[].labels.alertname'
```

---

## 🔧 Comandos Úteis

### **Prometheus**
```bash
# Status da configuração
curl -s http://localhost:9090/api/v1/status/config

# Recarregar configuração
curl -X POST http://localhost:9090/-/reload

# Query específica
curl -G 'http://localhost:9090/api/v1/query' --data-urlencode 'query=up'
```

### **Alertmanager** 
```bash
# Ver alertas ativos
curl -s http://localhost:9093/api/v1/alerts

# Recarregar configuração
curl -X POST http://localhost:9093/-/reload

# Status do serviço
curl -s http://localhost:9093/-/healthy
```

### **Docker**
```bash
# Logs dos serviços
docker compose logs -f prometheus
docker compose logs -f alertmanager

# Restart específico
docker compose restart prometheus
docker compose restart alertmanager
```

---

## 🔍 Troubleshooting

### **Problemas Comuns**

1. **Targets não aparecem**
   ```bash
   # Verificar configuração
   docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
   ```

2. **Alertas não são enviados**
   ```bash
   # Verificar conectividade Prometheus → Alertmanager
   curl -s http://localhost:9090/api/v1/alertmanagers
   ```

3. **Regras não carregam**
   ```bash
   # Validar sintaxe das regras
   docker exec prometheus promtool check rules /etc/prometheus/rules/*.yml
   ```

### **Reinicialização Limpa**
```bash
# Parar tudo
docker compose down

# Remover volumes (perde histórico)
docker volume rm prometheus_prometheus-data prometheus_alertmanager-data

# Reiniciar
docker compose up -d
```

---

## 📈 Próximos Passos Recomendados

1. **🎨 Adicionar Grafana** para dashboards visuais
2. **🔐 Configurar HTTPS** para produção
3. **📧 Configurar email** usando exemplos em `email-config-examples.md`
4. **💬 Integrar Slack/Teams** para notificações
5. **🔄 Setup de backup** para configurações e dados
6. **📱 Adicionar mais exporters** (MySQL, Redis, etc.)

---

## 📁 Estrutura Final

```
004-alertmanager/
├── alertmanager.yml              # ✅ Configuração avançada
├── docker-compose.yaml          # ✅ Serviço configurado
└── email-config-examples.md     # ✅ Exemplos de email

007-prometheus/
├── prometheus.yml                # ✅ Configuração otimizada
├── docker-compose.yaml          # ✅ Stack completo
├── webhook-test.py               # ✅ Servidor de teste
├── README.md                     # ✅ Documentação completa
└── rules/
    ├── basic-alerts.yml          # ✅ Alertas de sistema e containers
    └── prometheus-alerts.yml     # ✅ Alertas de monitoramento
```

---

## ✅ Status: CONFIGURAÇÃO CONCLUÍDA

🎉 **O sistema de monitoramento está completamente configurado e pronto para uso!**

- ✅ Prometheus coletando métricas de sistema e containers
- ✅ Alertmanager gerenciando alertas com roteamento inteligente  
- ✅ Regras de alerta abrangentes e categorizadas
- ✅ Sistema de teste para validação de alertas
- ✅ Documentação completa e exemplos práticos
- ✅ Configuração validada e testada

**Para iniciar:** `docker compose up -d` no diretório `007-prometheus/`
