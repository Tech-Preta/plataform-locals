# HashiCorp Vault - Instalação Local com Docker Compose

HashiCorp Vault é uma solução poderosa para armazenar e acessar segredos de forma segura (API keys, tokens, senhas, certificados, etc). Este guia mostra como rodar o Vault localmente, com HTTPS, usando Docker Compose e configuração persistente.

---

## ✅ STATUS: FUNCIONANDO
O Vault está configurado e operacional com:
- ✅ HTTPS/TLS habilitado com certificados autoassinados
- ✅ Storage Raft configurado e funcionando
- ✅ Persistência de dados local
- ✅ UI Web acessível
- ✅ Inicialização com 1 chave de unseal

---

## Pré-requisitos
- **Docker** e **Docker Compose** instalados
- **Vault CLI** (opcional, para comandos locais)

---

## 1. Estrutura de Diretórios
A estrutura está configurada para persistência e configuração:

```
005-vault/
├── audit/           # Logs de auditoria do Vault
├── config/          # Configurações
│   ├── tls/         # Certificados TLS
│   └── vault-config.hcl
├── data/            # Dados persistentes (Raft)
├── file/            # Storage adicional
├── logs/            # Logs do Vault
├── plugins/         # Plugins customizados
└── docker-compose.yaml
```

---

## 2. Certificados TLS
Os certificados já estão configurados em `005-vault/config/tls/`:
- ✅ `ca.crt` - Certificado CA
- ✅ `vault.crt` - Certificado do servidor
- ✅ `vault.key` - Chave privada

**Para recriar os certificados (se necessário):**
```bash
cd 005-vault/config
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout tls/vault.key \
  -out tls/vault.crt \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

cp tls/vault.crt tls/ca.crt
```

---

## 3. Permissões (IMPORTANTE)
O Vault roda como usuário UID 100 no container. Garanta as permissões corretas:

```bash
# Ajustar permissões das pastas de persistência
sudo chown -R 100:100 005-vault/data 005-vault/audit 005-vault/file 005-vault/logs 005-vault/plugins

# Ajustar permissões dos certificados TLS
sudo chown -R 100:100 005-vault/config/tls
sudo chmod 755 005-vault/config/tls
sudo chmod 644 005-vault/config/tls/*
```

---

---

## 3. docker-compose.yaml
## 4. Subir o Vault
No diretório `005-vault/`:
```bash
docker compose up -d
```

Verifique os logs para confirmar inicialização:
```bash
docker logs vault
```

Deve aparecer uma saída similar a:
```
==> Vault server started! Log data will stream in below:
[INFO]  core: Initializing version history cache for core
[INFO]  events: Starting event system
                 Storage: raft (HA available)
                 Version: Vault v1.19.5
```

---

## 5. Acessar o Vault

### Via Web UI
O Vault estará disponível em:
- **HTTPS:** `https://localhost:443`
- **Porta API:** `https://localhost:443/v1/sys/init`

### Via API
Verificar status:
```bash
curl -k https://localhost:443/v1/sys/seal-status
```

### Via CLI (se instalado)
```bash
export VAULT_ADDR="https://localhost:443"
export VAULT_SKIP_VERIFY=true
vault status
```

---

## 6. Inicialização e Unseal - Processo Completo

### 6.1 Primeira Verificação
Após subir o container, aguarde alguns segundos e verifique se precisa inicializar:

```bash
# Aguardar inicialização do container
sleep 10

# Verificar se o Vault precisa ser inicializado
curl -k https://localhost:443/v1/sys/init
```

**Resposta esperada para Vault não inicializado:**
```json
{"initialized":false}
```

### 6.2 Inicializar o Vault (primeira vez)
Quando `"initialized": false`, execute a inicialização:

```bash
curl -k -X POST -d '{"secret_shares":1,"secret_threshold":1}' \
  https://localhost:443/v1/sys/init | jq .
```

**Resposta esperada:**
```json
{
  "keys": [
    "c470a9a48d4395202ad5ff4f2a4e085baed8f037bf0e5b11649754294db31364"
  ],
  "keys_base64": [
    "EXEMPLO_BASE64_KEY_AQUI="
  ],
  "root_token": "hvs.EXEMPLO_ROOT_TOKEN_AQUI"
}
```

⚠️ **IMPORTANTE:** Salve o `root_token` e a chave `keys_base64` - você precisará deles!

### 6.3 Verificar Status do Vault
```bash
curl -k https://localhost:443/v1/sys/seal-status | jq .
```

**Resposta quando funcionando corretamente:**
```json
{
  "type": "shamir",
  "initialized": true,
  "sealed": false,
  "t": 1,
  "n": 1,
  "progress": 0,
  "nonce": "",
  "version": "1.19.5",
  "build_date": "2025-05-29T09:17:06Z",
  "migration": false,
  "cluster_name": "vault-cluster-9291b32a",
  "cluster_id": "f2e8656d-d53d-e488-8209-a443c2de4ada",
  "recovery_seal": false,
  "storage_type": "raft",
  "removed_from_cluster": false
}
```

### 6.4 Se o Vault estiver selado ("sealed": true)
Use a chave obtida na inicialização:
```bash
curl -k -X POST -d '{"key":"CHAVE_BASE64_AQUI"}' \
  https://localhost:443/v1/sys/unseal | jq .
```

**Exemplo com chave real:**
```bash
curl -k -X POST -d '{"key":"xHCppI1DlSAq1f9PKk4IW67Y8De/DlsRZJdUKU2zE2Q="}' \
  https://localhost:443/v1/sys/unseal | jq .
```

### 6.5 Verificar Logs do Container
Para monitorar o processo de inicialização:
```bash
docker logs vault --tail 20
```

**Logs indicando sucesso:**
```
[INFO]  storage.raft: entering leader state: leader="Node at localhost:8201 [Leader]"
[INFO]  core: acquired lock, enabling active operation
[INFO]  core: post-unseal setup starting
[INFO]  core: post-unseal setup complete
```

### 6.6 Reinicialização Completa (se necessário)
Se perdeu as chaves ou precisa começar do zero:

```bash
# 1. Parar o container
docker compose down

# 2. Limpar todos os dados
sudo rm -rf data/* audit/* logs/* file/*
sudo chown -R 100:100 data audit file logs plugins

# 3. Subir novamente
docker compose up -d

# 4. Aguardar e reinicializar
sleep 10
curl -k https://localhost:443/v1/sys/init
# Se retornar {"initialized":false}, proceder com inicialização
```

---

## 7. Login na Web UI

### Após inicialização bem-sucedida:
1. **Acesse:** `https://localhost:443`
2. **Método de autenticação:** Selecione **Token**
3. **Token:** Cole o `root_token` obtido na inicialização
   - Exemplo: `hvs.EXEMPLO_ROOT_TOKEN_AQUI`
4. **Clique em:** **Sign In**

### Exemplo de processo completo:
```bash
# 1. Inicializar e capturar resposta
INIT_RESPONSE=$(curl -k -X POST -d '{"secret_shares":1,"secret_threshold":1}' https://localhost:443/v1/sys/init)
echo $INIT_RESPONSE | jq .

# 2. Extrair root token
ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r '.root_token')
echo "Root Token: $ROOT_TOKEN"

# 3. Usar na UI Web ou via CLI
export VAULT_ADDR="https://localhost:443"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN="$ROOT_TOKEN"
```

---

---

## 6. Inicialize o Vault (apenas 1 chave de unseal)
```bash
docker exec vault vault operator init -key-shares=1 -key-threshold=1 -format=json > 005-vault/init-keys.json
```
- O arquivo `init-keys.json` conterá a única chave de unseal e o root token.

---

## 7. Unseal do Vault
```bash
docker exec vault vault operator unseal <unseal_key>
```
- Use a chave de unseal gerada no passo anterior.

---

## 8. Acesse a UI Web
Abra no navegador:
```
https://vault.nataliagranato.xyz
```
- Faça login com o **root token** gerado na inicialização.

---

## 9. Observações Importantes
- **Após cada restart do container, será necessário unseal novamente.**
- Guarde a chave de unseal e o root token em local seguro!
- O nome do host e certificados devem sempre bater com `vault.nataliagranato.xyz`.

---

## 10. Referências
- [Documentação Oficial Vault](https://developer.hashicorp.com/vault/docs)
- [Vault DockerHub](https://hub.docker.com/_/vault)

---

## 8. Troubleshooting

### Erros Comuns

**1. Permission denied ao acessar /vault/data/vault.db:**
```bash
sudo chown -R 100:100 005-vault/data 005-vault/audit 005-vault/file 005-vault/logs 005-vault/plugins
```

**2. Permission denied ao acessar certificados TLS:**
```bash
sudo chown -R 100:100 005-vault/config/tls
sudo chmod 755 005-vault/config/tls
sudo chmod 644 005-vault/config/tls/*
```

**3. Vault não inicia - verificar logs:**
```bash
docker logs vault
```

**4. Recriar containers e volumes:**
```bash
docker compose down
docker volume rm 005-vault_vault-data  # se usar volume nomeado
docker compose up -d
```

### Comandos Úteis
```bash
# Status do container
docker ps | grep vault

# Logs em tempo real
docker logs -f vault

# Logs específicos (últimas 20 linhas)
docker logs vault --tail 20

# Restart do serviço
docker compose restart

# Parar e remover tudo
docker compose down

# Acesso shell ao container
docker exec -it vault sh

# Verificar saúde do Vault
curl -k https://localhost:443/v1/sys/health | jq .

# Verificar status de inicialização
curl -k https://localhost:443/v1/sys/init

# Verificar status do seal
curl -k https://localhost:443/v1/sys/seal-status | jq .
```

### Estados do Vault
| Status                    | `initialized` | `sealed` | Descrição                |
| ------------------------- | ------------- | -------- | ------------------------ |
| **Novo**                  | `false`       | N/A      | Precisa ser inicializado |
| **Inicializado + Selado** | `true`        | `true`   | Precisa fazer unseal     |
| **Funcionando**           | `true`        | `false`  | Pronto para uso          |

---

## 9. Configuração Adicional

### Adicionar entrada no /etc/hosts (OPCIONAL)
⚠️ **Não é mais necessário para desenvolvimento local** - agora usamos `localhost` diretamente.

Se por algum motivo quiser usar um domínio customizado:
```bash
echo "127.0.0.1 meu-vault.local" | sudo tee -a /etc/hosts
```
E ajustar as configurações correspondentes.

### Variáveis de ambiente para Vault CLI
```bash
export VAULT_ADDR="https://localhost:443"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN="seu_root_token_aqui"
```

---

## 10. Notas de Segurança

⚠️ **ATENÇÃO:** Esta configuração é para desenvolvimento local. Para produção:

1. Use certificados válidos (não autoassinados)
2. Configure múltiplas chaves de unseal (3 ou 5)
3. Configure auto-unseal com cloud providers
4. Habilite auditoria
5. Configure políticas de acesso
6. Use secrets engines específicos
7. Configure high availability (HA)

---

**🎉 Vault configurado e funcionando!**

### Acesso rápido:
- **Web UI:** https://localhost:443
- **API:** https://localhost:443/v1/
- **Status:** `curl -k https://localhost:443/v1/sys/seal-status`

### Exemplo de token e chave obtidos na inicialização:
```json
{
  "keys": ["EXEMPLO_HEX_KEY_AQUI"],
  "keys_base64": ["EXEMPLO_BASE64_KEY_AQUI="],
  "root_token": "hvs.EXEMPLO_ROOT_TOKEN_AQUI"
}
```

### Estado esperado após inicialização:
```json
{
  "type": "shamir",
  "initialized": true,
  "sealed": false,
  "cluster_name": "vault-cluster-9291b32a",
  "storage_type": "raft"
}
```

**O Vault está pronto para armazenar e gerenciar seus secrets!** 🔐
