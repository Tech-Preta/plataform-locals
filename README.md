# Plataform Locals

Uma plataforma local completa para desenvolvimento e produção usando Kubernetes (K3s) e diversas ferramentas modernas de DevOps.

## 🏗️ Arquitetura

Este projeto implementa uma stack completa de ferramentas para desenvolvimento local, utilizando K3s como base do cluster Kubernetes e diversas aplicações containerizadas.

### ⚙️ Stack Tecnológica

#### 🎛️ **Orquestração & Infraestrutura**
- **K3s** - Distribuição leve do Kubernetes para clusters locais
- **Cilium** - CNI (Container Network Interface) avançado com eBPF
- **Traefik** - Ingress Controller e Load Balancer
- **Terraform** - Infrastructure as Code (planejado)

#### 🗄️ **Armazenamento & Dados**
- **MinIO** - Object Storage compatível com S3
- **OpenSearch** - Search e Analytics Engine

#### 📊 **Monitoramento & Observabilidade**
- **Grafana** - Visualização de métricas e dashboards
- **AlertManager** - Gerenciamento de alertas
- **Umami** - Analytics web privacy-focused

#### 🔐 **Segurança & Secrets**
- **Vault** - Gerenciamento de secrets e criptografia

#### 🐳 **Gerenciamento de Containers**
- **Portainer** - Interface web para Docker/Kubernetes
- **Rancher** - Plataforma de gerenciamento Kubernetes

#### 🏠 **Dashboard & Interface**
- **Homepage** - Dashboard unificado para serviços

## 🚀 Getting Started

### Pré-requisitos

- **Sistema Operacional**: Ubuntu 20.04+ ou similar (Debian, CentOS, RHEL)
- **RAM**: Mínimo 4GB (recomendado 8GB+)
- **CPU**: Mínimo 2 vCPUs (recomendado 4+ vCPUs)
- **Disco**: Mínimo 50GB livres
- **Docker**: Instalado e configurado
- **Kubectl**: Cliente Kubernetes

### 🔧 Instalação Rápida

#### 1. Clone o Repositório
```bash
git clone <repository-url>
cd plataform-locals
```

#### 2. Instalar K3s com Customizações
```bash
# Tornar o script executável
chmod +x 000-kubernetes/init/install-local-k3s.sh

# Executar instalação com CIDRs customizados
cd 000-kubernetes/init
./install-local-k3s.sh 10.42.0.0/16 10.43.0.0/16
```

#### 3. Verificar Instalação
```bash
kubectl get nodes
kubectl config current-context  # Deve mostrar: nataliagranato
```

## 📁 Estrutura do Projeto

```
plataform-locals/
├── 000-kubernetes/          # Cluster K3s base
│   ├── init/
│   │   └── install-local-k3s.sh
│   └── README.md
├── 001-minio/              # Object Storage S3-compatible
├── 002-opensearch/         # Search & Analytics
├── 003-grafana/            # Dashboards & Visualização
├── 004-alertmanager/       # Gerenciamento de Alertas
├── 005-vault/              # Secrets Management
├── 006-traefik/            # Ingress Controller
├── 007-umami/              # Web Analytics
├── 008-homepage/           # Dashboard Unificado
├── 009-portainer/          # Container Management
└── 010-rancher/            # Kubernetes Management
```

## 🎯 Funcionalidades Implementadas

### ✅ **K3s Cluster**
- ✅ Instalação automatizada via script
- ✅ Nome de cluster customizado (`nataliagranato`)
- ✅ CIDRs customizados para pods e serviços
- ✅ Traefik desabilitado (para instalação via Helm)
- ✅ Flannel desabilitado (para uso do Cilium)
- ✅ Network Policy desabilitado (Cilium gerencia)
- ✅ Kubeconfig ajustado automaticamente

### 🔄 **Em Desenvolvimento**
- 🔄 Instalação e configuração do Cilium
- 🔄 Instalação do Traefik via Helm
- 🔄 Configuração dos demais serviços

## 🛠️ Configurações Avançadas

### K3s Customizações
- **Cluster Name**: `nataliagranato`
- **Pod CIDR**: `10.42.0.0/16`
- **Service CIDR**: `10.43.0.0/16`
- **CNI**: Cilium (Flannel desabilitado)
- **Ingress**: Traefik (instalação externa)
- **ServiceLB**: Mantido ativo

### Rede e Conectividade
- IP do nó detectado automaticamente
- Kubeconfig ajustado para IP real do nó
- Contexto e cluster nomeados como `nataliagranato`

## 📚 Documentação

Cada componente possui sua própria documentação:

- [📖 K3s Setup](000-kubernetes/README.md)
- [📖 MinIO](001-minio/)
- [📖 OpenSearch](002-opensearch/)
- [📖 Grafana](003-grafana/)
- [📖 AlertManager](004-alertmanager/)
- [📖 Vault](005-vault/)
- [📖 Traefik](006-traefik/)
- [📖 Umami](007-umami/)
- [📖 Homepage](008-homepage/)
- [📖 Portainer](009-portainer/)
- [📖 Rancher](010-rancher/)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📝 Roadmap

### 🎯 **Próximas Implementações**
- [ ] Cilium CNI com eBPF
- [ ] Traefik com certificados automáticos
- [ ] CertManager para TLS
- [ ] Prometheus + Grafana stack completa
- [ ] ArgoCD para CI/CD
- [ ] Kyverno para políticas de segurança
- [ ] Velero para backup/restore
- [ ] Cloudflare Tunnel integration

### 🔮 **Futuro**
- [ ] Multi-node K3s cluster
- [ ] GitOps completo
- [ ] Service Mesh (Istio/Linkerd)
- [ ] Observabilidade avançada
- [ ] Automação completa via Terraform

## 🆘 Suporte

Para dúvidas, problemas ou sugestões:

- 🐛 [Issues](https://github.com/nataliagranato/plataform-locals/issues)
- 💬 [Discussions](https://github.com/nataliagranato/plataform-locals/discussions)
- 💰 [GitHub Sponsors](https://github.com/sponsors/nataliagranato)

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

Feito com ❤️ por [Natália Granato](https://github.com/nataliagranato)
