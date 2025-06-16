# 🤖 Ollama + Open WebUI

Este diretório contém a configuração Docker para executar o Ollama (servidor de modelos LLM) junto com o Open WebUI (interface web) com persistência de dados.

## 🎯 Componentes

### 🧠 **Ollama** (porta 11434)
- **Função:** Servidor de modelos de linguagem (LLM) local
- **API:** http://localhost:11434
- **Modelos:** Llama, Mistral, CodeLlama, etc.
- **Dados:** Volume persistente `ollama-data`

### 🌐 **Open WebUI** (porta 3000)
- **Função:** Interface web para interagir com modelos
- **UI:** http://localhost:3000
- **Dados:** Volume persistente `open-webui-data`
- **Features:** Chat, histórico, configurações

---

## 🚀 Início Rápido

### 1. Subir os serviços
```bash
cd 012-ollama
docker compose up -d
```

### 2. Verificar se estão rodando
```bash
docker compose ps
```

### 3. Acessar a interface
- **Open WebUI**: http://localhost:3000
- **API Ollama**: http://localhost:11434

### 4. Criar primeiro usuário
- Acesse http://localhost:3000
- Clique em "Sign Up" 
- Crie sua conta (primeiro usuário será admin)

---

## 📦 Baixando Modelos

### Via Interface Web (Recomendado)
1. Acesse http://localhost:3000
2. Faça login
3. Clique no ícone de configurações (⚙️)
4. Vá em "Models" 
5. Digite o nome do modelo (ex: `llama3.2:3b`)
6. Clique em "Pull Model"

### Via CLI
```bash
# Baixar modelo Llama 3.2 (3B parâmetros)
docker exec ollama ollama pull llama3.2:3b

# Baixar modelo CodeLlama (para código)
docker exec ollama ollama pull codellama:7b

# Baixar modelo Mistral (boa performance)
docker exec ollama ollama pull mistral:7b

# Listar modelos instalados
docker exec ollama ollama list
```

### Via API
```bash
# Baixar modelo via API
curl -X POST http://localhost:11434/api/pull \
  -H "Content-Type: application/json" \
  -d '{"name": "llama3.2:3b"}'
```

---

## 🎯 Modelos Recomendados

### 💡 **Para Iniciantes (menor uso de recursos)**
| Modelo        | Tamanho | RAM | Descrição                        |
| ------------- | ------- | --- | -------------------------------- |
| `llama3.2:1b` | ~1.3GB  | 4GB | Modelo pequeno e rápido          |
| `llama3.2:3b` | ~2.0GB  | 6GB | Bom equilíbrio tamanho/qualidade |
| `qwen2.5:3b`  | ~1.9GB  | 6GB | Modelo chinês muito eficiente    |

### 🔥 **Para Melhor Qualidade (mais recursos)**
| Modelo         | Tamanho | RAM  | Descrição                       |
| -------------- | ------- | ---- | ------------------------------- |
| `llama3.2:7b`  | ~4.1GB  | 12GB | Excelente qualidade geral       |
| `mistral:7b`   | ~4.1GB  | 12GB | Muito bom para tarefas variadas |
| `codellama:7b` | ~3.8GB  | 12GB | Especializado em código         |

### 🚀 **Para Hardware Potente**
| Modelo         | Tamanho | RAM  | Descrição                   |
| -------------- | ------- | ---- | --------------------------- |
| `llama3.1:70b` | ~40GB   | 80GB | Qualidade próxima ao GPT-4  |
| `qwen2.5:72b`  | ~41GB   | 80GB | Modelo multilíngue avançado |

---

## 🖥️ Suporte a GPU (NVIDIA)

### Habilitar GPU
1. **Editar docker-compose.yml:**
   ```yaml
   # Descomentar as linhas de GPU no serviço ollama:
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: all
             capabilities: [gpu]
   ```

2. **Verificar NVIDIA Container Toolkit:**
   ```bash
   # Verificar se está instalado
   nvidia-smi
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   ```

3. **Reiniciar serviços:**
   ```bash
   docker compose down
   docker compose up -d
   ```

### Verificar uso de GPU
```bash
# Ver uso de GPU
nvidia-smi

# Logs do Ollama para verificar GPU
docker compose logs ollama | grep -i gpu
```

---

## 🔧 Configuração Avançada

### Variáveis de Ambiente - Ollama
```yaml
environment:
  - OLLAMA_HOST=0.0.0.0:11434        # Host/porta do servidor
  - OLLAMA_ORIGINS=*                 # CORS origins permitidas
  - OLLAMA_MODELS=/root/.ollama      # Diretório dos modelos
  - OLLAMA_KEEP_ALIVE=5m             # Tempo para manter modelo em memória
  - OLLAMA_NUM_PARALLEL=1            # Requests paralelos
  - OLLAMA_MAX_LOADED_MODELS=1       # Máximo de modelos carregados
```

### Variáveis de Ambiente - Open WebUI
```yaml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434  # URL do Ollama
  - WEBUI_SECRET_KEY=your-secret-key     # Chave secreta (MUDE!)
  - WEBUI_JWT_SECRET_KEY=jwt-secret      # JWT secret (MUDE!)
  - ENABLE_SIGNUP=true                   # Permitir cadastro
  - DEFAULT_USER_ROLE=user               # Role padrão
  - WEBUI_AUTH=true                      # Autenticação obrigatória
  - MAX_FILE_SIZE=10485760               # Tamanho máximo de arquivo (10MB)
```

---

## 🧪 Testando a Instalação

### 1. Verificar API do Ollama
```bash
# Verificar se API está respondendo
curl http://localhost:11434/api/tags

# Testar geração de texto (após baixar um modelo)
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Hello, world!",
    "stream": false
  }'
```

### 2. Verificar Open WebUI
```bash
# Verificar se está respondendo
curl -I http://localhost:3000

# Ver logs
docker compose logs open-webui
```

### 3. Teste de Chat
1. Acesse http://localhost:3000
2. Faça login
3. Inicie um chat
4. Digite: "Olá, como você pode me ajudar?"

---

## 📊 Monitoramento e Logs

### Logs dos Serviços
```bash
# Ver logs de ambos os serviços
docker compose logs -f

# Logs apenas do Ollama
docker compose logs -f ollama

# Logs apenas do Open WebUI
docker compose logs -f open-webui
```

### Uso de Recursos
```bash
# Ver uso de recursos
docker stats

# Espaço dos volumes
docker system df -v

# Modelos instalados e tamanhos
docker exec ollama ollama list
```

### Status dos Serviços
```bash
# Status dos containers
docker compose ps

# Verificar health dos serviços
curl -s http://localhost:11434/api/tags | jq .
curl -I http://localhost:3000
```

---

## 🔒 Segurança

### 🚨 **IMPORTANTE: Alterar Chaves Secretas**
```bash
# Gerar chaves seguras
openssl rand -hex 32  # Para WEBUI_SECRET_KEY
openssl rand -hex 32  # Para WEBUI_JWT_SECRET_KEY
```

### 🛡️ **Configurações de Segurança**
```yaml
environment:
  # Desabilitar cadastro público em produção
  - ENABLE_SIGNUP=false
  
  # Definir role padrão mais restritivo
  - DEFAULT_USER_ROLE=pending
  
  # Limitar tamanho de arquivos
  - MAX_FILE_SIZE=5242880  # 5MB
```

### 🔐 **Acesso Restrito (Produção)**
```yaml
# Adicionar proxy reverso com autenticação
# Ou restringir portas no firewall
ports:
  - "127.0.0.1:3000:8080"  # Apenas localhost
  - "127.0.0.1:11434:11434"  # Apenas localhost
```

---

## 📂 Gerenciamento de Dados

### Backup dos Dados
```bash
# Parar serviços
docker compose down

# Backup dos volumes
docker run --rm -v ollama-data:/source -v $(pwd):/backup alpine \
  tar czf /backup/ollama-backup-$(date +%Y%m%d).tar.gz -C /source .

docker run --rm -v open-webui-data:/source -v $(pwd):/backup alpine \
  tar czf /backup/webui-backup-$(date +%Y%m%d).tar.gz -C /source .

# Reiniciar serviços
docker compose up -d
```

### Restaurar Backup
```bash
# Parar serviços
docker compose down

# Restaurar volumes
docker run --rm -v ollama-data:/dest -v $(pwd):/backup alpine \
  tar xzf /backup/ollama-backup-YYYYMMDD.tar.gz -C /dest

docker run --rm -v open-webui-data:/dest -v $(pwd):/backup alpine \
  tar xzf /backup/webui-backup-YYYYMMDD.tar.gz -C /dest

# Reiniciar serviços
docker compose up -d
```

### Limpeza de Espaço
```bash
# Remover modelos não utilizados
docker exec ollama ollama rm MODEL_NAME

# Limpar dados do Docker
docker system prune -f

# Ver espaço usado
du -sh /var/lib/docker/volumes/ollama_*
```

---

## 🔧 Troubleshooting

### ❌ Problemas Comuns

#### 1. **Ollama não inicia**
```bash
# Verificar logs
docker compose logs ollama

# Verificar se porta está em uso
sudo netstat -tlnp | grep :11434

# Reiniciar apenas o Ollama
docker compose restart ollama
```

#### 2. **Open WebUI não conecta ao Ollama**
```bash
# Verificar conectividade
docker exec open-webui curl http://ollama:11434/api/tags

# Verificar variável de ambiente
docker exec open-webui env | grep OLLAMA_BASE_URL
```

#### 3. **Modelo não baixa**
```bash
# Verificar espaço em disco
df -h

# Verificar conectividade
docker exec ollama curl -I https://ollama.com

# Baixar manualmente
docker exec -it ollama ollama pull llama3.2:3b
```

#### 4. **Performance ruim**
```bash
# Verificar recursos
docker stats

# Ajustar configurações de memória
# Editar OLLAMA_KEEP_ALIVE e OLLAMA_MAX_LOADED_MODELS
```

### 🔄 Reinicialização Limpa
```bash
# Parar tudo
docker compose down

# Remover volumes (CUIDADO: perde dados!)
docker volume rm ollama_ollama-data ollama_open-webui-data

# Recriar e iniciar
docker compose up -d
```

---

## 🚀 Próximos Passos

### 🔌 **Integrações Possíveis**
1. **Proxy Reverso** (Traefik/Nginx) para HTTPS
2. **Autenticação Externa** (LDAP/OAuth)
3. **Monitoramento** com Prometheus
4. **Load Balancer** para múltiplas instâncias

### 📱 **Apps Compatíveis**
- **Continue.dev** (VS Code extension)
- **Cursor** (AI code editor)
- **LangChain** (development framework)
- **Open Interpreter** (AI assistant)

### 🎯 **Casos de Uso**
- **Assistente de código** local
- **Análise de documentos** privada
- **Chatbot personalizado** para empresa
- **Desenvolvimento AI** sem dependência de APIs externas

---

## 📚 Recursos Úteis

- **Ollama Docs**: https://ollama.com/docs
- **Open WebUI**: https://openwebui.com
- **Model Library**: https://ollama.com/library
- **GPU Support**: https://docs.nvidia.com/datacenter/cloud-native/

---

## ✅ Status: Configuração Pronta

🎉 **Seu ambiente Ollama + Open WebUI está configurado e pronto para uso!**

**Para iniciar:**
```bash
docker compose up -d
```

**Acesse:** http://localhost:3000
