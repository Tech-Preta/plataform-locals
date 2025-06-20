# Keycloak Identity and Access Management

Keycloak é uma solução open-source de Identity and Access Management (IAM) que fornece autenticação, autorização, SSO (Single Sign-On), gerenciamento de usuários e muito mais.

## 📁 Estrutura do Projeto

```
014-keycloack/
├── docker-compose.yaml      # Configuração principal
├── README.md               # Esta documentação
├── .env.example           # Variáveis de ambiente
├── keycloak-manager.sh    # Script de gerenciamento
├── realms/                # Configurações de realms
│   └── local-dev-realm.json
├── themes/                # Temas customizados
├── providers/             # Extensões/plugins
├── conf/                  # Configurações customizadas
└── init-scripts/          # Scripts de inicialização do DB
```

## 🚀 Quick Start

### 1. Preparar o Ambiente

```bash
# Ir para o diretório
cd 014-keycloack

# Copiar arquivo de exemplo
cp .env.example .env

# Editar variáveis de ambiente
nano .env
```

### 2. Iniciar os Serviços

```bash
# Subir os serviços
docker-compose up -d

# Verificar logs
docker-compose logs -f

# Verificar status
docker-compose ps
```

### 3. Acessar Keycloak

- **URL**: http://localhost:8080
- **Admin Console**: http://localhost:8080/admin
- **Usuário Admin**: admin
- **Senha Admin**: admin_password_change_this

⚠️ **IMPORTANTE**: Altere as senhas padrão antes de usar em produção!

## 🔧 Configuração

### Variáveis de Ambiente

Principais variáveis no `.env`:

```bash
# Database
POSTGRES_PASSWORD=keycloak_password_change_this
POSTGRES_ROOT_PASSWORD=postgres_root_password_change_this

# Keycloak Admin
KEYCLOAK_ADMIN_PASSWORD=admin_password_change_this

# Hostname (para produção)
KC_HOSTNAME=auth.yourdomain.com
KC_PROXY=edge

# Features adicionais
KC_FEATURES=token-exchange,admin-fine-grained-authz,declarative-user-profile
```

### Configuração para Produção

1. **Alterar senhas padrão**
2. **Configurar HTTPS**
3. **Ajustar hostname**
4. **Remover porta do PostgreSQL**
5. **Configurar backup do banco**

```yaml
# Para produção, alterar no docker-compose.yaml:
environment:
  KC_HOSTNAME: auth.yourdomain.com
  KC_HOSTNAME_STRICT: true
  KC_HOSTNAME_STRICT_HTTPS: true
  KC_PROXY: edge
  KC_HTTP_ENABLED: false  # Apenas HTTPS

# Remover exposição da porta do PostgreSQL:
# ports:
#   - "5432:5432"  # Comentar ou remover
```

## 🎯 Funcionalidades

### Recursos do Keycloak

- **Single Sign-On (SSO)**
- **Identity Brokering** (LDAP, AD, SAML, OAuth)
- **Social Login** (Google, Facebook, GitHub, etc.)
- **Multi-Factor Authentication (MFA)**
- **User Federation**
- **Fine-grained Authorization**
- **Protocol Support** (SAML 2.0, OpenID Connect, OAuth 2.0)
- **Admin Console** web-based
- **Account Management Console**

### Protocolos Suportados

- **OpenID Connect** (recomendado)
- **SAML 2.0**
- **OAuth 2.0**
- **JWT Tokens**

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Aplicações    │◄──►│   Keycloak   │◄──►│   PostgreSQL    │
│                 │    │              │    │                 │
│ - Web Apps      │    │ - Auth Server│    │ - User Data     │
│ - Mobile Apps   │    │ - Admin UI   │    │ - Config Data   │
│ - APIs          │    │ - Account UI │    │ - Session Data  │
└─────────────────┘    └──────────────┘    └─────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
              ┌─────▼─────┐      ┌──────▼──────┐
              │  Themes   │      │  Providers  │
              │           │      │             │
              │ - Custom  │      │ - LDAP      │
              │ - Branding│      │ - Social    │
              └───────────┘      └─────────────┘
```

## 🛠️ Script de Gerenciamento

O `keycloak-manager.sh` fornece comandos úteis:

```bash
# Tornar executável
chmod +x keycloak-manager.sh

# Ver comandos disponíveis
./keycloak-manager.sh

# Exemplos de uso:
./keycloak-manager.sh start      # Iniciar serviços
./keycloak-manager.sh stop       # Parar serviços
./keycloak-manager.sh restart    # Reiniciar serviços
./keycloak-manager.sh logs       # Ver logs
./keycloak-manager.sh status     # Status dos containers
./keycloak-manager.sh backup     # Backup do banco
./keycloak-manager.sh restore    # Restaurar backup
```

## 📋 Realms e Configuração

### Realm Padrão (Master)

O realm `master` é usado para administração do Keycloak. Não use para aplicações.

### Realm de Desenvolvimento

Um realm de exemplo `local-dev` está incluído em `realms/local-dev-realm.json` com:

- **Usuários de teste**
- **Roles básicas**
- **Clients configurados**
- **Configurações de desenvolvimento**

### Importar Realm

```bash
# Via docker-compose (automático na inicialização)
# O arquivo em realms/ é importado automaticamente

# Via Admin Console:
# 1. Acesse Admin Console
# 2. Hover sobre "Master" no canto superior esquerdo
# 3. Clique em "Add realm"
# 4. Selecione arquivo JSON ou configure manualmente
```

## 🔐 Integração com Aplicações

### OpenID Connect (Recomendado)

1. **Criar Client no Keycloak**
2. **Configurar Redirect URIs**
3. **Obter Client ID e Secret**
4. **Configurar biblioteca OIDC na aplicação**

### Exemplo de Client Configuration

```json
{
  "clientId": "my-app",
  "redirectUris": ["http://localhost:3000/*"],
  "webOrigins": ["http://localhost:3000"],
  "protocol": "openid-connect",
  "publicClient": false,
  "bearerOnly": false,
  "standardFlowEnabled": true,
  "serviceAccountsEnabled": true
}
```

### URLs Importantes

```bash
# OpenID Connect Discovery
http://localhost:8080/realms/{realm}/.well-known/openid_configuration

# Token Endpoint
http://localhost:8080/realms/{realm}/protocol/openid-connect/token

# Authorization Endpoint
http://localhost:8080/realms/{realm}/protocol/openid-connect/auth

# User Info Endpoint
http://localhost:8080/realms/{realm}/protocol/openid-connect/userinfo

# Logout Endpoint
http://localhost:8080/realms/{realm}/protocol/openid-connect/logout
```

## 🎨 Customização

### Temas

```bash
# Estrutura de tema customizado
themes/
└── custom-theme/
    ├── login/
    │   ├── theme.properties
    │   ├── login.ftl
    │   └── resources/
    │       ├── css/
    │       ├── js/
    │       └── img/
    ├── account/
    └── admin/
```

### Providers Customizados

```bash
# Adicionar JARs de extensões
providers/
├── custom-authenticator.jar
├── custom-event-listener.jar
└── custom-user-storage.jar
```

## 🔗 Integração com Traefik

As labels do Traefik estão configuradas no docker-compose.yaml:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.keycloak.rule=Host(`auth.localhost`)
  - traefik.http.routers.keycloak.entrypoints=web
  - traefik.http.services.keycloak.loadbalancer.server.port=8080
```

Para produção com HTTPS:

```yaml
labels:
  - traefik.http.routers.keycloak-secure.rule=Host(`auth.yourdomain.com`)
  - traefik.http.routers.keycloak-secure.entrypoints=websecure
  - traefik.http.routers.keycloak-secure.tls=true
  - traefik.http.routers.keycloak-secure.tls.certresolver=letsencrypt
```

## 📊 Monitoramento

### Health Check

```bash
# Health endpoint
curl http://localhost:8080/health

# Ready endpoint
curl http://localhost:8080/health/ready

# Live endpoint
curl http://localhost:8080/health/live
```

### Métricas

```bash
# Prometheus metrics (se habilitado)
curl http://localhost:8080/metrics

# Management interface
curl http://localhost:9990/management
```

### Logs

```bash
# Ver logs em tempo real
docker-compose logs -f keycloak

# Logs do banco
docker-compose logs -f keycloak-db

# Logs com timestamp
docker-compose logs -t keycloak
```

## 💾 Backup e Restauração

### Backup do Banco

```bash
# Via script
./keycloak-manager.sh backup

# Manual
docker-compose exec keycloak-db pg_dump -U keycloak keycloak > backup.sql
```

### Backup de Configuração

```bash
# Exportar realm
docker-compose exec keycloak /opt/keycloak/bin/kc.sh export \
  --realm my-realm \
  --file /tmp/my-realm-export.json

# Copiar do container
docker-compose cp keycloak:/tmp/my-realm-export.json ./backups/
```

### Restauração

```bash
# Via script
./keycloak-manager.sh restore backup.sql

# Manual do banco
docker-compose exec -T keycloak-db psql -U keycloak keycloak < backup.sql
```

## 🔧 Troubleshooting

### Problemas Comuns

1. **Container não inicia**
   ```bash
   # Verificar logs
   docker-compose logs keycloak
   
   # Verificar se DB está pronto
   docker-compose logs keycloak-db
   ```

2. **Erro de conexão com banco**
   ```bash
   # Verificar network
   docker network ls
   
   # Testar conectividade
   docker-compose exec keycloak ping keycloak-db
   ```

3. **Problema de permissões**
   ```bash
   # Verificar volumes
   docker-compose config
   
   # Recriar volumes
   docker-compose down -v
   docker-compose up -d
   ```

4. **Lentidão na inicialização**
   ```bash
   # Aumentar timeout no healthcheck
   # Verificar recursos disponíveis
   docker stats
   ```

### Reset Completo

```bash
# Parar e remover tudo
docker-compose down -v --remove-orphans

# Remover imagens (opcional)
docker-compose down --rmi all

# Recriar do zero
docker-compose up -d
```

## 🚀 Produção

### Checklist de Produção

- [ ] Alterar todas as senhas padrão
- [ ] Configurar HTTPS obrigatório
- [ ] Configurar hostname correto
- [ ] Remover exposição da porta do PostgreSQL
- [ ] Configurar backup automático
- [ ] Configurar monitoramento
- [ ] Configurar logs centralizados
- [ ] Testar disaster recovery
- [ ] Configurar rate limiting
- [ ] Revisar configurações de segurança

### Configurações de Segurança

```bash
# Variáveis para produção
KC_HOSTNAME_STRICT=true
KC_HOSTNAME_STRICT_HTTPS=true
KC_HTTP_ENABLED=false
KC_PROXY=edge

# Headers de segurança
KC_SPI_STICKY_SESSION_ENCODER_INFINISPAN_SHOULD_ATTACH_ROUTE=false
```

### Performance Tuning

```bash
# JVM options
JAVA_OPTS="-Xms512m -Xmx2g -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m"

# Cache configuration
KC_CACHE=ispn
KC_CACHE_STACK=tcp
KC_CACHE_CONFIG_FILE=cache-ispn.xml
```

## 📚 Recursos Adicionais

### Documentação Oficial

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/)
- [Securing Applications Guide](https://www.keycloak.org/docs/latest/securing_apps/)

### Exemplos de Integração

- [Spring Boot + Keycloak](https://www.keycloak.org/docs/latest/securing_apps/#_spring_boot_adapter)
- [Node.js + Keycloak](https://www.keycloak.org/docs/latest/securing_apps/#_nodejs_adapter)
- [React + Keycloak](https://www.keycloak.org/docs/latest/securing_apps/#_javascript_adapter)

### Comunidade

- [Keycloak GitHub](https://github.com/keycloak/keycloak)
- [Keycloak Discourse](https://keycloak.discourse.group/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/keycloak)

---

## 📞 Suporte

Para questões específicas desta configuração, consulte:

1. **Logs dos containers**: `docker-compose logs`
2. **Status dos serviços**: `docker-compose ps`
3. **Documentação oficial do Keycloak**
4. **Issues do projeto no GitHub**

---

*Configuração testada com Keycloak 23.0 e PostgreSQL 15*
