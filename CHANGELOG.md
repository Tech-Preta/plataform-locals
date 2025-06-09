# CHANGELOG

Todas as mudanças notáveis ​​neste projeto serão documentadas neste arquivo.

O formato é baseado em [Mantenha um Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e este projeto adere a [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.2.0] - 2025-06-09

### ✅ Adicionado
- **K3s Cluster Base**: Implementação completa do cluster K3s single-node
- **Script de Instalação Automatizada**: `install-local-k3s.sh` com customizações
- **Configuração de Rede**: CIDRs customizados para pods (10.42.0.0/16) e serviços (10.43.0.0/16)
- **Nome de Cluster Customizado**: Cluster e contexto nomeados como `nataliagranato`
- **Kubeconfig Otimizado**: Ajuste automático do IP real do nó no kubeconfig
- **Preparação para CNI**: Flannel desabilitado, preparado para Cilium
- **Preparação para Ingress**: Traefik padrão desabilitado, preparado para instalação via Helm
- **Documentação Completa**: README principal e específico do K3s

### 🔧 Configurado
- **Componentes Desabilitados**: Traefik, Flannel, Network Policy (para uso externo)
- **Componentes Ativos**: CoreDNS, Metrics Server, Local Path Provisioner, ServiceLB
- **Permissões**: Usuário adicionado ao grupo k3s automaticamente
- **Contexto kubectl**: Configurado automaticamente com nome personalizado

### 🛠️ Técnico
- **K3s Version**: v1.32.5+k3s1
- **Installation Method**: curl | sh com flags customizadas
- **Network**: Preparado para Cilium CNI
- **Ingress**: Preparado para Traefik via Helm
- **Storage**: Local Path Provisioner ativo

## [0.1.0] - 2025-06-09

### ✅ Adicionado
- **Estrutura do Projeto**: Organização inicial com 11 stacks planejadas
- **Documentação Base**: README principal, LICENSE, CODE_OF_CONDUCT
- **Docker Compose Stacks**: Configurações para MinIO, OpenSearch, Grafana, etc.
- **Planejamento**: Arquitetura definida para 000-kubernetes até 010-rancher

### 📁 Estrutura Criada
```
000-kubernetes/     # K3s Cluster (✅ Implementado)
001-minio/         # Object Storage (📋 Planejado)
002-opensearch/    # Search & Analytics (📋 Planejado)
003-grafana/       # Monitoring (📋 Planejado)
004-alertmanager/  # Alerting (📋 Planejado)
005-vault/         # Secrets (📋 Planejado)
006-traefik/       # Ingress (📋 Planejado)
007-umami/         # Analytics (📋 Planejado)
008-homepage/      # Dashboard (📋 Planejado)
009-portainer/     # Container Mgmt (📋 Planejado)
010-rancher/       # K8s Mgmt (📋 Planejado)
```

## [Unreleased] - Próximas Implementações

### 🔄 Em Desenvolvimento
- **Cilium CNI**: Instalação e configuração via Helm
- **Traefik Ingress**: Instalação via Helm com certificados automáticos
- **CertManager**: Gerenciamento automático de certificados TLS

### 📋 Planejado
- **MinIO**: Object Storage S3-compatible
- **OpenSearch**: Search engine e analytics
- **Grafana Stack**: Monitoramento completo com Prometheus
- **Vault**: Gerenciamento de secrets
- **ArgoCD**: GitOps e CI/CD
- **Kyverno**: Políticas de segurança
- **Velero**: Backup e restore

### 🚀 Roadmap Futuro
- **Multi-node K3s**: Expansão para cluster distribuído
- **Service Mesh**: Istio ou Linkerd
- **Observabilidade Avançada**: Jaeger, OpenTelemetry
- **Terraform Integration**: Infrastructure as Code completa
- **Cloudflare Integration**: Tunnel e DNS automático

---

### Legenda
- ✅ **Adicionado**: Novas funcionalidades
- 🔧 **Configurado**: Mudanças de configuração
- 🛠️ **Técnico**: Detalhes técnicos importantes
- 🔄 **Em Desenvolvimento**: Trabalho em progresso
- 📋 **Planejado**: Funcionalidades futuras
- 🚀 **Roadmap**: Visão de longo prazo
straightforward as possible.

### Added

### Changed

### Fixed

### Breaking Changes
-->

## [0.0.0] - 2025-03-25

### Added
- Esse é apenas um exemplo de descrição.
