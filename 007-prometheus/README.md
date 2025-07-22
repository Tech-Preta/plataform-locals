# Prometheus + Alertmanager - Monitoring Stack

Este diretório contém a configuração completa de monitoramento com Prometheus e Alertmanager para ambiente Docker local, totalmente integrado e pronto para produção.

## 🎯 Componentes

### 📊 **Prometheus** (porta 9090)
- **Função:** Coleta de métricas e armazenamento de dados de monitoramento
- **UI:** http://localhost:9090
- **Configuração:** `prometheus.yml`
- **Regras:** `rules/*.yml`

### 🚨 **Alertmanager** (porta 9093)
- **Função:** Gerenciamento e envio de alertas
- **UI:** http://localhost:9093
- **Configuração:** `../004-alertmanager/alertmanager.yml`

### 🖥️ **Node Exporter** (porta 9100)
- **Função:** Métricas do sistema host (CPU, memória, disco)
- **Métricas:** http://localhost:9100/metrics

### 🐳 **cAdvisor** (porta 8080)
- **Função:** Métricas de containers Docker
- **UI:** http://localhost:8080
- **Métricas:** http://localhost:8080/metrics

---

## 🚀 Início Rápido

### 1. Subir o stack completo
```bash
cd 007-prometheus
docker compose up -d
```

### 2. Verificar se todos os serviços estão rodando
```bash
docker compose ps
```

### 3. Iniciar servidor de teste para webhooks (opcional)
```bash
# Em outro terminal
python3 webhook-test.py
```

### 4. Acessar as interfaces

| Serviço           | URL                           | Descrição                       |
| ----------------- | ----------------------------- | ------------------------------- |
| **Prometheus**    | http://localhost:9090         | Interface principal de métricas |
| **Alertmanager**  | http://localhost:9093         | Gerenciamento de alertas        |
| **Node Exporter** | http://localhost:9100/metrics | Métricas do sistema             |
| **cAdvisor**      | http://localhost:8080         | Métricas de containers          |
| **Webhook Test**  | http://localhost:5001         | Servidor de teste para alertas  |

---

## 📊 Monitoramento

### 🎯 Targets Configurados
O Prometheus monitora automaticamente:

- **prometheus**: Métricas do próprio Prometheus
- **alertmanager**: Status e métricas do Alertmanager  
- **node-exporter**: Métricas do sistema (CPU, memória, disco, rede)
- **cadvisor**: Métricas de containers Docker
- **docker-containers**: Autodiscovery de containers Docker
- **vault**: Métricas do HashiCorp Vault (se executando)

### 🔍 Queries Úteis

#### Sistema
```promql
# CPU usage por instância
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Uso de memória
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Espaço em disco disponível
(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

# Load average
node_load1
```

#### Containers
```promql
# Containers em execução
sum(container_last_seen) by (name)

# Uso de CPU por container
rate(container_cpu_usage_seconds_total[5m]) * 100

# Uso de memória por container
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# Network I/O por container
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])
```

#### Prometheus/Alertmanager
```promql
# Status dos targets
up

# Rate de ingestão de samples
rate(prometheus_tsdb_symbol_table_size_bytes[5m])

# Alertas ativos
alertmanager_alerts

# Notificações enviadas
rate(alertmanager_notifications_total[5m])
```

---

## 🚨 Sistema de Alertas

### 📋 Tipos de Alertas Configurados

#### 🖥️ Sistema (Node Exporter)
- **HighCPUUsage**: CPU > 85% por 3 min (warning)
- **CriticalCPUUsage**: CPU > 95% por 1 min (critical)
- **HighMemoryUsage**: Memória > 80% por 3 min (warning)
- **CriticalMemoryUsage**: Memória > 90% por 1 min (critical)
- **LowDiskSpace**: Disco < 20% por 2 min (warning)
- **CriticalDiskSpace**: Disco < 10% por 1 min (critical)
- **NodeDown**: Node Exporter offline por 1 min (critical)

#### 🐳 Containers (cAdvisor)
- **ContainerDown**: Container offline por 2 min (critical)
- **ContainerHighMemoryUsage**: Memória > 85% por 3 min (warning)
- **ContainerCriticalMemoryUsage**: Memória > 95% por 1 min (critical)
- **ContainerHighCPUUsage**: CPU > 80% por 3 min (warning)
- **ContainerRestartingTooMuch**: > 12 restarts/hora (warning)

#### 📊 Monitoramento (Prometheus/Alertmanager)
- **PrometheusTargetDown**: Target offline por 30s (critical)
- **PrometheusConfigurationReloadFailure**: Falha na configuração (critical)
- **AlertmanagerDown**: Alertmanager offline por 1 min (critical)
- **AlertmanagerConfigurationReloadFailure**: Falha na configuração (critical)

### 🎯 Receivers Configurados

| Receiver              | Descrição                      | Endpoint                         |
| --------------------- | ------------------------------ | -------------------------------- |
| **default-receiver**  | Alertas gerais                 | http://127.0.0.1:5001/           |
| **critical-alerts**   | Alertas críticos               | http://127.0.0.1:5001/critical   |
| **system-alerts**     | Alertas de sistema             | http://127.0.0.1:5001/system     |
| **docker-alerts**     | Alertas de containers          | http://127.0.0.1:5001/docker     |
| **monitoring-alerts** | Alertas do stack de monitoring | http://127.0.0.1:5001/monitoring |

---

## 🧪 Testando Alertas

### 1. Usar o servidor de webhook de teste
```bash
# Terminal 1: Iniciar o webhook server
python3 webhook-test.py

# Terminal 2: Gerar carga alta de CPU
stress --cpu 8 --timeout 300s

# Terminal 3: Monitorar alertas
watch 'curl -s http://localhost:9093/api/v1/alerts | jq .'
```

### 2. Simular alerta manual
```bash
# Simular target down
docker compose stop node-exporter

# Verificar alertas no Alertmanager
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | select(.labels.alertname=="NodeExporterDown")'

# Restaurar serviço
docker compose start node-exporter
```

### 3. Testar configuração do Alertmanager
```bash
# Validar configuração
curl -s http://localhost:9093/-/healthy

# Recarregar configuração
curl -X POST http://localhost:9093/-/reload

# Ver status da configuração
curl -s http://localhost:9093/api/v1/status | jq .
```

---

## 🔧 Comandos Úteis

### 📊 Prometheus
```bash
# Verificar configuração
curl -s http://localhost:9090/api/v1/status/config | jq .

# Ver targets ativos
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].labels'

# Recarregar configuração
curl -X POST http://localhost:9090/-/reload

# Ver regras carregadas
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].name'

# Query específica
curl -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up' | jq .
```

### 🚨 Alertmanager
```bash
# Ver alertas ativos
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | {alertname: .labels.alertname, status: .status.state}'

# Ver silences ativos
curl -s http://localhost:9093/api/v1/silences | jq .

# Criar silence (exemplo)
curl -X POST http://localhost:9093/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{"matchers":[{"name":"alertname","value":"HighCPUUsage"}],"startsAt":"2024-01-01T00:00:00Z","endsAt":"2024-01-01T01:00:00Z","comment":"Maintenance","createdBy":"admin"}'
```

### 🐳 Docker
```bash
# Ver logs dos serviços
docker compose logs -f prometheus
docker compose logs -f alertmanager

# Restart individual services
docker compose restart prometheus
docker compose restart alertmanager

# Ver métricas dos containers
docker stats

# Ver volumes
docker volume ls | grep prometheus
```

---

## 🔍 Troubleshooting

### ❌ Problemas Comuns

#### 1. **Prometheus não consegue coletar métricas de containers**
```bash
# Verificar se o socket do Docker está acessível
ls -la /var/run/docker.sock

# Verificar se o volume está montado no container
docker inspect prometheus | grep docker.sock
```

#### 2. **Alertmanager não recebe alertas**
```bash
# Verificar se o Prometheus consegue alcançar o Alertmanager
curl -s http://localhost:9090/api/v1/alertmanagers | jq .

# Verificar logs do Alertmanager
docker compose logs alertmanager | grep -i error
```

#### 3. **Regras não estão carregando**
```bash
# Verificar sintaxe das regras
docker exec prometheus promtool check rules /etc/prometheus/rules/*.yml

# Ver status das regras
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | {name: .name, rules: .rules | length}'
```

#### 4. **Targets não aparecem**
```bash
# Verificar configuração do Prometheus
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Ver targets com erros
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

### 🔄 Reinicialização Limpa

```bash
# Parar todos os serviços
docker compose down

# Remover volumes (CUIDADO: perde dados históricos)
docker volume rm prometheus_prometheus-data prometheus_alertmanager-data

# Recriar e iniciar
docker compose up -d

# Verificar se tudo subiu corretamente
docker compose ps
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:9093/-/healthy
```

---

## 📈 Dashboards e Visualização

### 🎨 Grafana (Opcional)
Para adicionar Grafana ao stack:

```yaml
# Adicionar ao docker-compose.yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  restart: unless-stopped
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
  volumes:
    - grafana-data:/var/lib/grafana
  networks:
    - monitoring
```

### 📊 Dashboards Recomendados
- **Node Exporter Full**: ID 1860
- **Docker and system monitoring**: ID 893
- **Prometheus Stats**: ID 2
- **cAdvisor**: ID 14282

---

## 🔐 Segurança

### ⚠️ Recomendações

1. **Não usar em produção sem autenticação**
2. **Configurar HTTPS para produção**
3. **Limitar acesso via firewall/proxy reverso**
4. **Usar senhas fortes para SMTP**
5. **Configurar retenção adequada de dados**
6. **Monitorar logs de segurança**

### 🔒 Configuração de Produção
```yaml
# Exemplo para produção com autenticação básica
# prometheus.yml
global:
  external_labels:
    cluster: 'production'
    
# Adicionar autenticação básica
basic_auth:
  username: 'prometheus'
  password: 'secure_password'
```

---

## 📚 Próximos Passos

1. **Integração com Grafana** para dashboards visuais
2. **Configuração de HTTPS** com certificados SSL
3. **Backup automático** de configurações e dados
4. **Integração com Slack/Teams** para notificações
5. **Adição de mais exporters** (MySQL, Redis, etc.)
6. **Configuração de alta disponibilidade**

---

## 📞 Suporte

Para dúvidas sobre esta configuração:
1. Verificar logs dos containers
2. Consultar documentação oficial do Prometheus/Alertmanager
3. Testar configurações com o webhook de teste
4. Validar sintaxe com promtool

**Documentação oficial:**
- [Prometheus](https://prometheus.io/docs/)
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [cAdvisor](https://github.com/google/cadvisor)

---

## 📋 Configurações

### Prometheus (`prometheus.yml`)
- **Intervalo de coleta:** 15 segundos
- **Descoberta automática:** Containers Docker
- **Targets estáticos:** Prometheus, Alertmanager, Node Exporter, cAdvisor
- **Integração:** Alertmanager configurado

### Alertmanager (`../004-alertmanager/alertmanager.yml`)
- **Agrupamento:** Por alertname, cluster, service
- **Tempo de espera:** 10 segundos
- **Intervalo de repetição:** 1 hora
- **Receivers:** Email, webhook, Slack (configurável)

### Regras de Alerta (`rules/`)
- **basic-alerts.yml:** Alertas de sistema (CPU, memória, disco, containers)
- **prometheus-alerts.yml:** Alertas específicos do Prometheus/Alertmanager

---

## 🔔 Alertas Configurados

### Sistema (Node Exporter)
- ⚠️ **CPU alto:** > 80% por 2 minutos
- ⚠️ **Memória alta:** > 85% por 2 minutos  
- 🚨 **Disco baixo:** < 10% por 1 minuto

### Containers (cAdvisor)
- 🚨 **Container parado:** Down por 1 minuto
- ⚠️ **CPU container alto:** > 80% por 2 minutos
- ⚠️ **Memória container alta:** > 90% por 2 minutos

### Prometheus/Alertmanager
- 🚨 **Target perdido:** Exporters offline
- ⚠️ **Erro de configuração:** Reload falhou
- ⚠️ **Muitos restarts:** > 2 em 15 minutos

---

## 🛠️ Comandos Úteis

### Gerenciamento do stack
```bash
# Subir todos os serviços
docker compose up -d

# Ver logs em tempo real
docker compose logs -f

# Parar todos os serviços
docker compose down

# Remover volumes (perda de dados)
docker compose down -v
```

### Verificação de configuração
```bash
# Testar configuração do Prometheus
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Testar regras de alerta
docker exec prometheus promtool check rules /etc/prometheus/rules/*.yml

# Testar configuração do Alertmanager
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
```

### Reload de configurações
```bash
# Recarregar configuração do Prometheus (sem restart)
curl -X POST http://localhost:9090/-/reload

# Recarregar configuração do Alertmanager
curl -X POST http://localhost:9093/-/reload
```

---

## 🔧 Personalização

### Adicionar novos alertas
1. Edite arquivos em `rules/` ou crie novos
2. Recarregue a configuração: `curl -X POST http://localhost:9090/-/reload`

### Configurar notificações
1. Edite `../004-alertmanager/alertmanager.yml`
2. Configure SMTP, Slack, Discord, etc.
3. Recarregue: `curl -X POST http://localhost:9093/-/reload`

### Adicionar novos exporters
1. Adicione ao `prometheus.yml` na seção `scrape_configs`
2. Adicione ao `docker-compose.yaml` se for container

---

## 📊 Métricas Importantes

### Queries úteis no Prometheus
```promql
# CPU usage por container
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memória usage por container  
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100

# Disk usage
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

# Network I/O
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])
```

---

## 🔒 Notas de Segurança

⚠️ **ATENÇÃO:** Esta configuração é para desenvolvimento local. Para produção:

1. Configure autenticação no Prometheus e Alertmanager
2. Use TLS/HTTPS
3. Configure firewalls apropriados
4. Use secrets para credenciais SMTP
5. Configure backup dos dados do Prometheus

---

**🎉 Stack de monitoramento configurado e funcionando!**
- **Prometheus:** http://localhost:9090
- **Alertmanager:** http://localhost:9093
- **Métricas em tempo real** e **alertas automáticos** ✅
