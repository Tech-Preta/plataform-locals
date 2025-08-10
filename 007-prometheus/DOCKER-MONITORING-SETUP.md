# 🐳 Configuração de Monitoramento do Docker

## 📊 **Status Atual do Monitoramento**

### ✅ **Já Configurado:**
- **cAdvisor**: Métricas detalhadas de containers (CPU, memória, rede, I/O)
- **Docker Socket**: Autodiscovery de containers via `/var/run/docker.sock`
- **Prometheus**: Jobs configurados para cAdvisor e descoberta de containers

### ❗ **Precisa Configurar:**
- **Docker Daemon**: Métricas nativas do daemon Docker (estatísticas gerais, API calls, etc.)

---

## 🔧 **Configuração do Docker Daemon (Necessária)**

### **Passo 1: Executar o script de configuração**
```bash
cd 007-prometheus
sudo ./configure-docker-metrics.sh
```

**O script irá:**
1. ✅ Fazer backup da configuração atual
2. ✅ Adicionar `metrics-addr` ao `/etc/docker/daemon.json`
3. ✅ Reiniciar o Docker daemon
4. ✅ Testar se as métricas estão funcionando

### **Passo 2: Verificar se funcionou**
```bash
# Testar endpoint de métricas
curl http://localhost:9323/metrics | head -n 10

# Verificar se Docker está rodando
sudo systemctl status docker
```

### **Passo 3: Reiniciar Prometheus**
```bash
# As configurações do Prometheus já incluem o job docker-daemon
docker compose restart prometheus

# Verificar se o target apareceu
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job=="docker-daemon")'
```

---

## 📊 **Tipos de Métricas Coletadas**

### 🐳 **Docker Daemon (porto 9323)**
- **engine_daemon_network_actions_seconds**: Ações de rede
- **engine_daemon_container_actions_seconds**: Ações de containers  
- **engine_daemon_image_actions_seconds**: Ações de imagens
- **go_memstats_**: Estatísticas de memória do daemon
- **process_**: Estatísticas do processo Docker
- **http_requests_**: Requests da API Docker

### 📦 **cAdvisor (porta 8080)**
- **container_cpu_usage_seconds_total**: Uso de CPU por container
- **container_memory_usage_bytes**: Uso de memória por container
- **container_network_**: Estatísticas de rede por container
- **container_fs_**: Estatísticas do sistema de arquivos

### 🖥️ **Node Exporter (porta 9100)**
- **node_cpu_seconds_total**: CPU do host
- **node_memory_**: Memória do host  
- **node_filesystem_**: Discos do host
- **node_network_**: Rede do host

---

## 🧪 **Testando a Configuração**

### **1. Verificar todos os targets**
```bash
# Via Prometheus API
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastScrape: .lastScrape}'

# Via interface web
# Acesse: http://localhost:9090/targets
```

### **2. Queries úteis para Docker**

#### **Docker Daemon:**
```promql
# Rate de API calls
rate(engine_daemon_container_actions_seconds_count[5m])

# Memória do daemon
go_memstats_alloc_bytes{job="docker-daemon"}

# Goroutines do daemon
go_goroutines{job="docker-daemon"}
```

#### **Containers (cAdvisor):**
```promql
# CPU por container
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memória por container  
container_memory_usage_bytes / 1024 / 1024

# Containers rodando
count by (name) (container_last_seen{name!=""})
```

### **3. Verificar alertas funcionando**
```bash
# Listar alertas ativos
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | {alertname: .labels.alertname, status: .status.state}'

# Iniciar webhook para ver alertas
python3 webhook-test.py
```

---

## 🎯 **Arquitetura Completa de Monitoramento**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Docker Host   │    │   Containers    │    │  Applications   │
│                 │    │                 │    │                 │
│ Node Exporter   │    │   cAdvisor      │    │ Custom Metrics  │
│ (port 9100)     │    │   (port 8080)   │    │ (port 9090+)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Docker Daemon   │
                    │ (port 9323)     │
                    └─────────────────┘
                                 │
                                 │
                    ┌─────────────────┐
                    │   Prometheus    │
                    │   (port 9090)   │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Alertmanager   │
                    │   (port 9093)   │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Notifications  │
                    │ (webhook/email) │
                    └─────────────────┘
```

---

## 🚨 **Alertas para Docker Configurados**

### **Sistema (Node Exporter)**
- High CPU/Memory usage
- Low disk space
- Node offline

### **Containers (cAdvisor)**  
- Container down
- High container CPU/memory
- Container restarting frequently

### **Docker Daemon**
- Docker daemon down
- High API call rate
- Daemon restart detection

---

## 🔧 **Comandos Úteis**

### **Docker Daemon**
```bash
# Ver configuração atual
sudo cat /etc/docker/daemon.json

# Verificar status
sudo systemctl status docker

# Ver métricas diretamente
curl http://localhost:9323/metrics | grep engine_daemon

# Logs do daemon
sudo journalctl -u docker.service -f
```

### **Prometheus**
```bash
# Recarregar configuração
curl -X POST http://localhost:9090/-/reload

# Verificar configuração
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Ver targets
curl -s http://localhost:9090/api/v1/targets
```

### **Troubleshooting**
```bash
# Se métricas do daemon não aparecem:
sudo netstat -tlnp | grep :9323

# Se Prometheus não consegue conectar:
docker exec prometheus nslookup host.docker.internal

# Logs do Prometheus
docker compose logs prometheus | grep -i docker-daemon
```

---

## ✅ **Checklist Final**

- [ ] ✅ cAdvisor rodando (métricas de containers)
- [ ] ✅ Node Exporter rodando (métricas do host)  
- [ ] ✅ Docker socket montado (autodiscovery)
- [ ] ❗ **Docker daemon configurado** (`./configure-docker-metrics.sh`)
- [ ] ❗ **Job docker-daemon no Prometheus** (já adicionado)
- [ ] ❗ **Prometheus reiniciado** (`docker compose restart prometheus`)

---

## 📚 **Referências**

- [Docker Metrics Documentation](https://docs.docker.com/config/daemon/prometheus/)
- [Prometheus Docker SD](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#docker_sd_config)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
