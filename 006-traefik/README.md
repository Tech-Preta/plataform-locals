# 🔀 Traefik - Modern Reverse Proxy

Este diretório contém a configuração completa do Traefik v3, um moderno reverse proxy e load balancer com descoberta automática de serviços, SSL automático e dashboard web.

## 🎯 Funcionalidades

### 🚀 **Core Features**
- **Auto Service Discovery**: Descobre serviços Docker automaticamente
- **SSL/TLS Automático**: Let's Encrypt integration
- **Load Balancing**: Múltiplos algoritmos de balanceamento
- **Middlewares**: Rate limiting, autenticação, headers de segurança
- **Dashboard Web**: Interface gráfica para monitoramento

### 📊 **Monitoring & Observability**
- **Métricas Prometheus**: Exposição de métricas para monitoramento
- **Logs Estruturados**: Access logs e error logs
- **Health Checks**: Verificação de saúde dos serviços
- **Real-time Dashboard**: Visualização em tempo real

---

## 🚀 Início Rápido

### 1. **Inicializar Traefik**
```bash
# Usando o script de gerenciamento
./traefik-manager.sh start

# Ou manualmente
docker network create traefik-network
docker compose up -d
```

### 2. **Verificar Status**
```bash
./traefik-manager.sh status
```

### 3. **Acessar Dashboard**
- **Local**: http://localhost:8080
- **Domain**: http://traefik.localhost (adicionar ao /etc/hosts)
- **Métricas**: http://localhost:8080/metrics

---

## 📊 Interfaces de Acesso

| Serviço       | URL                           | Descrição                      |
| ------------- | ----------------------------- | ------------------------------ |
| **Dashboard** | http://localhost:8080         | Interface principal do Traefik |
| **API**       | http://localhost:8080/api     | API REST para configuração     |
| **Métricas**  | http://localhost:8080/metrics | Métricas Prometheus            |
| **Health**    | http://localhost:8080/ping    | Health check endpoint          |

---

## 🔧 Configuração

### 📁 **Estrutura de Arquivos**
```
006-traefik/
├── docker-compose.yaml           # Configuração principal
├── traefik-manager.sh            # Script de gerenciamento
├── config/
│   ├── middlewares.yml           # Middlewares personalizados
│   └── services-examples.yml     # Exemplos de serviços
├── logs/                         # Logs do Traefik
└── letsencrypt/                  # Certificados SSL
    └── acme.json                 # Dados do Let's Encrypt
```

### ⚙️ **Configurações Principais**

#### **Entry Points**
- **Port 80**: HTTP traffic
- **Port 443**: HTTPS traffic  
- **Port 8080**: Dashboard e API

#### **Providers**
- **Docker**: Auto-discovery de containers
- **File**: Configurações dinâmicas em YAML

#### **Certificate Resolvers**
- **Let's Encrypt**: SSL automático via HTTP challenge

---

## 🐳 Adicionando Serviços ao Traefik

### **Método 1: Labels no Docker Compose**

```yaml
version: '3.8'

services:
  my-app:
    image: nginx:alpine
    labels:
      # Habilitar Traefik
      - traefik.enable=true
      
      # Configurar rota HTTP
      - traefik.http.routers.my-app.rule=Host(`app.localhost`)
      - traefik.http.routers.my-app.entrypoints=web
      - traefik.http.services.my-app.loadbalancer.server.port=80
      
      # Configurar rota HTTPS (produção)
      - traefik.http.routers.my-app-secure.rule=Host(`app.yourdomain.com`)
      - traefik.http.routers.my-app-secure.entrypoints=websecure
      - traefik.http.routers.my-app-secure.tls=true
      - traefik.http.routers.my-app-secure.tls.certresolver=letsencrypt
      
      # Middlewares
      - traefik.http.routers.my-app.middlewares=compression,security-headers
      
    networks:
      - traefik-network

networks:
  traefik-network:
    external: true
```

### **Método 2: Configuração Dinâmica (File Provider)**

Criar arquivo em `config/my-service.yml`:

```yaml
http:
  routers:
    my-service:
      rule: "Host(`api.localhost`)"
      entrypoints:
        - "web"
      service: "my-service"
      middlewares:
        - "rate-limit"
        - "security-headers"

  services:
    my-service:
      loadBalancer:
        servers:
          - url: "http://my-api:8080"
        healthCheck:
          path: "/health"
          interval: "30s"
```

---

## 🛠️ Comandos Úteis

### **Script de Gerenciamento**
```bash
# Iniciar Traefik
./traefik-manager.sh start

# Parar Traefik
./traefik-manager.sh stop

# Reiniciar Traefik
./traefik-manager.sh restart

# Ver status
./traefik-manager.sh status

# Ver logs
./traefik-manager.sh logs

# Validar configuração
./traefik-manager.sh validate

# Adicionar serviço à rede
./traefik-manager.sh add-service container-name

# Gerar hash de autenticação
./traefik-manager.sh generate-auth admin password123
```

### **Docker Commands**
```bash
# Ver logs em tempo real
docker compose logs -f traefik

# Recarregar configuração
docker compose restart traefik

# Verificar containers na rede
docker network inspect traefik-network

# Conectar container existente
docker network connect traefik-network container-name
```

### **API Calls**
```bash
# Listar routers
curl -s http://localhost:8080/api/http/routers | jq .

# Listar serviços
curl -s http://localhost:8080/api/http/services | jq .

# Ver middlewares
curl -s http://localhost:8080/api/http/middlewares | jq .

# Health check
curl http://localhost:8080/ping
```

---

## 🔒 Middlewares Disponíveis

### **Segurança**
- **security-headers**: Headers de segurança padrão
- **basic-auth**: Autenticação HTTP básica
- **admin-whitelist**: Whitelist de IPs para admin
- **redirect-to-https**: Redirecionamento para HTTPS

### **Performance**
- **compression**: Compressão gzip/brotli
- **rate-limit**: Limitação de rate por IP
- **strip-prefix**: Remoção de prefixos de URL

### **Exemplo de Uso**
```yaml
labels:
  - traefik.http.routers.app.middlewares=compression,security-headers,rate-limit
```

---

## 📈 Integração com Prometheus

### **Métricas Disponíveis**
- `traefik_service_requests_total`: Total de requests por serviço
- `traefik_service_request_duration_seconds`: Duração dos requests
- `traefik_entrypoint_requests_total`: Requests por entrypoint
- `traefik_router_requests_total`: Requests por router

### **Configuração no Prometheus**
```yaml
scrape_configs:
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
    scrape_interval: 15s
    metrics_path: '/metrics'
```

### **Queries Úteis**
```promql
# Rate de requests
rate(traefik_service_requests_total[5m])

# Latência média
rate(traefik_service_request_duration_seconds_sum[5m]) / rate(traefik_service_request_duration_seconds_count[5m])

# Códigos de erro
increase(traefik_service_requests_total{code=~"4..|5.."}[5m])
```

---

## 🌐 Configuração de Produção

### **1. HTTPS Obrigatório**
Descomente no docker-compose.yaml:
```yaml
# Global redirect from HTTP to HTTPS
- --entrypoints.web.http.redirections.entrypoint.to=websecure
- --entrypoints.web.http.redirections.entrypoint.scheme=https
```

### **2. Dashboard Seguro**
```yaml
labels:
  - traefik.http.routers.traefik-secure.rule=Host(`traefik.yourdomain.com`)
  - traefik.http.routers.traefik-secure.entrypoints=websecure
  - traefik.http.routers.traefik-secure.tls=true
  - traefik.http.routers.traefik-secure.tls.certresolver=letsencrypt
  - traefik.http.routers.traefik-secure.middlewares=traefik-auth
```

### **3. Configurar Email para Let's Encrypt**
```yaml
- --certificatesresolvers.letsencrypt.acme.email=admin@yourdomain.com
```

### **4. Desabilitar API Insecura**
```yaml
- --api.insecure=false
```

---

## 🔍 Troubleshooting

### **Problemas Comuns**

#### **1. Serviço não aparece no dashboard**
```bash
# Verificar se container está na rede
docker network inspect traefik-network

# Verificar labels
docker inspect container-name | jq '.[0].Config.Labels'

# Verificar logs
./traefik-manager.sh logs
```

#### **2. SSL não funciona**
```bash
# Verificar acme.json
ls -la letsencrypt/acme.json

# Verificar permissões
chmod 600 letsencrypt/acme.json

# Verificar logs do Let's Encrypt
docker compose logs traefik | grep -i acme
```

#### **3. 404 Gateway Timeout**
```bash
# Verificar se serviço está rodando
docker ps | grep service-name

# Verificar conectividade
docker exec traefik ping service-name

# Verificar configuração do serviço
curl -s http://localhost:8080/api/http/services | jq '.[] | select(.name=="service-name")'
```

#### **4. Rate Limit atingido**
```bash
# Verificar middleware de rate limit
curl -s http://localhost:8080/api/http/middlewares | jq '.[] | select(.name=="rate-limit")'

# Ajustar configuração em config/middlewares.yml
```

### **Logs Úteis**
```bash
# Todos os logs
./traefik-manager.sh logs

# Apenas erros
docker compose logs traefik | grep -i error

# Access logs
tail -f logs/access.log

# Logs específicos do Let's Encrypt
docker compose logs traefik | grep -i "acme\|letsencrypt"
```

---

## 🔄 Exemplos de Integração

### **WordPress com SSL**
```yaml
wordpress:
  image: wordpress:latest
  labels:
    - traefik.enable=true
    - traefik.http.routers.wp.rule=Host(`blog.yourdomain.com`)
    - traefik.http.routers.wp.entrypoints=websecure
    - traefik.http.routers.wp.tls=true
    - traefik.http.routers.wp.tls.certresolver=letsencrypt
    - traefik.http.services.wp.loadbalancer.server.port=80
  networks:
    - traefik-network
```

### **API com Rate Limiting**
```yaml
api:
  image: my-api:latest
  labels:
    - traefik.enable=true
    - traefik.http.routers.api.rule=Host(`api.yourdomain.com`)
    - traefik.http.routers.api.middlewares=rate-limit,security-headers
    - traefik.http.services.api.loadbalancer.server.port=8080
  networks:
    - traefik-network
```

### **Admin Panel com Autenticação**
```yaml
admin:
  image: admin-panel:latest
  labels:
    - traefik.enable=true
    - traefik.http.routers.admin.rule=Host(`admin.yourdomain.com`)
    - traefik.http.routers.admin.middlewares=basic-auth,admin-whitelist
    - traefik.http.services.admin.loadbalancer.server.port=3000
  networks:
    - traefik-network
```

---

## 📚 Próximos Passos

1. **🔐 Configurar autenticação** para dashboard em produção
2. **📊 Integrar com Grafana** para dashboards visuais
3. **🔄 Setup de backup** para configurações e certificados
4. **🌐 Configurar DNS** para domínios personalizados
5. **📱 Adicionar mais middlewares** conforme necessário
6. **🔍 Configurar logging centralizado**

---

## 📞 Referências

- [Documentação Oficial do Traefik](https://doc.traefik.io/traefik/)
- [Traefik v3 Migration Guide](https://doc.traefik.io/traefik/migration/v2-to-v3/)
- [Let's Encrypt Integration](https://doc.traefik.io/traefik/https/acme/)
- [Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Middlewares Reference](https://doc.traefik.io/traefik/middlewares/http/overview/)

---

## ✅ Status: TRAEFIK CONFIGURADO

🎉 **O Traefik está completamente configurado e pronto para uso!**

**Para iniciar:** `./traefik-manager.sh start`
