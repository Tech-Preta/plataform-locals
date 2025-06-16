# K3s Terraform Installation

Este projeto Terraform automatiza a instalação do K3s (Lightweight Kubernetes) em um servidor remoto via SSH.

## Pré-requisitos

- Terraform >= 1.0
- Acesso SSH ao servidor de destino
- Chave SSH configurada
- Servidor Ubuntu/Debian ou CentOS/RHEL

## Configuração

1. **Configure as variáveis no `terraform.tfvars`:**
   ```hcl
   node_ip = "SEU_IP_DO_SERVIDOR"  # OBRIGATÓRIO
   ssh_user = "seu_usuario"
   ssh_private_key_path = "~/.ssh/id_rsa"
   ```

2. **Personalize outras configurações (opcional):**
   ```hcl
   cluster_cidr = "10.42.0.0/16"
   service_cidr = "10.43.0.0/16"
   k3s_version = "latest"  # ou uma versão específica como "v1.28.4+k3s1"
   ```

## Uso

```bash
# Inicializar Terraform
terraform init

# Planejar a instalação
terraform plan

# Aplicar a configuração
terraform apply

# Verificar o cluster
export KUBECONFIG=~/.kube/config
kubectl get nodes
```

## O que faz

- Instala o K3s no servidor especificado
- Configura o kubeconfig local
- Desabilita o Traefik por padrão (para usar ingress customizado)
- Configura Flannel backend como "none" (para usar CNI customizado)
- Configura CIDRs personalizados para cluster e serviços
- Adiciona verificações de saúde do cluster

## Variáveis

| Variável               | Descrição             | Padrão         | Obrigatória |
| ---------------------- | --------------------- | -------------- | ----------- |
| `node_ip`              | IP do servidor        | -              | ✅           |
| `ssh_user`             | Usuário SSH           | nataliagranato | ❌           |
| `ssh_private_key_path` | Caminho da chave SSH  | ~/.ssh/id_rsa  | ❌           |
| `cluster_cidr`         | CIDR do cluster       | 10.42.0.0/16   | ❌           |
| `service_cidr`         | CIDR dos serviços     | 10.43.0.0/16   | ❌           |
| `k3s_version`          | Versão do K3s         | latest         | ❌           |
| `kubeconfig_path`      | Caminho do kubeconfig | ~/.kube/config | ❌           |

## Outputs

- `kubeconfig_path`: Caminho do arquivo kubeconfig
- `node_ip`: IP do nó do cluster
- `cluster_info`: Informações completas do cluster
- `kubectl_config_command`: Comando para configurar kubectl

## Limpeza

```bash
terraform destroy
```

## Solução de Problemas

### Erro de conexão SSH
- Verifique se o IP está correto
- Confirme que a chave SSH está configurada
- Teste a conexão: `ssh -i ~/.ssh/id_rsa usuario@ip`

### K3s não inicia
- Verifique os logs: `sudo journalctl -u k3s`
- Confirme que não há conflitos de rede com os CIDRs

### Kubeconfig não funciona
- Verifique as permissões do arquivo
- Confirme que o caminho está correto
- Execute: `export KUBECONFIG=~/.kube/config`
