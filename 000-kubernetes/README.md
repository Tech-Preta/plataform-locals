# K3s Single Node Installation

O K3s é uma distribuição leve do Kubernetes, ideal para ambientes de desenvolvimento e produção em pequena escala. Este guia cobre a instalação de um cluster K3s em um único nó bare metal, com customizações específicas para uso com Cilium e Traefik.

## 🎯 Objetivos

- ✅ Cluster K3s single-node otimizado
- ✅ Nome de cluster customizado (`nataliagranato`)
- ✅ CNI preparado para Cilium (Flannel desabilitado)
- ✅ Ingress preparado para Traefik via Helm
- ✅ Kubeconfig automaticamente configurado
- ✅ ServiceLB ativo para LoadBalancer services

## 🔧 Pré-requisitos

- **Sistema Operacional**: Ubuntu 20.04+ ou similar (Debian, CentOS, RHEL)
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **CPU**: Mínimo 2 vCPUs
- **Disco**: Mínimo 20GB livres
- **Rede**: Conectividade de rede estável
- **Usuário**: Permissões sudo

## 🚀 Instalação Automatizada

### Método Recomendado: Script Customizado

```bash
# 1. Tornar o script executável
chmod +x install-local-k3s.sh

# 2. Executar com CIDRs customizados (opcional)
./install-local-k3s.sh 10.42.0.0/16 10.43.0.0/16

# 3. Ou executar com valores padrão
./install-local-k3s.sh
```

### O que o Script Faz

1. **Instala K3s** com flags customizadas:
   - `--cluster-cidr`: CIDR para pods (padrão: 10.42.0.0/16)
   - `--service-cidr`: CIDR para serviços (padrão: 10.43.0.0/16)
   - `--disable traefik`: Remove Traefik padrão (será instalado via Helm)
   - `--flannel-backend=none`: Desabilita Flannel (Cilium será o CNI)
   - `--disable-network-policy`: Desabilita network policy do K3s

2. **Configura Kubeconfig**:
   - Detecta IP real do nó automaticamente
   - Substitui 127.0.0.1 pelo IP real
   - Customiza nome do cluster/contexto para `nataliagranato`
   - Configura permissões corretas

3. **Ajusta Permissões**:
   - Adiciona usuário ao grupo k3s
   - Configura acessos de leitura necessários



## ✅ Verificação da Instalação

### 1. Verificar Status do Cluster
```bash
# Verificar contexto atual
kubectl config current-context
# Deve retornar: nataliagranato

# Verificar nós do cluster
kubectl get nodes
# Deve mostrar: mgc (hostname) com status NotReady até Cilium ser instalado

# Verificar pods do sistema
kubectl get pods -A
# CoreDNS, metrics-server e local-path-provisioner em Pending até CNI estar ativo
```

### 2. Verificar Configurações de Rede
```bash
# Verificar CIDRs configurados
kubectl cluster-info dump | grep -E "(cluster-cidr|service-cluster-ip-range)"

# Verificar se Flannel foi desabilitado
kubectl get pods -n kube-system | grep flannel
# Não deve retornar nenhum pod

# Verificar se Traefik foi desabilitado
kubectl get pods -n kube-system | grep traefik
# Não deve retornar nenhum pod
```

### 3. Status do Sistema
```bash
# Verificar serviço K3s
sudo systemctl status k3s.service --no-pager

# Verificar logs se necessário
sudo journalctl -xeu k3s.service --no-pager -f
```

## 🔧 Configurações Aplicadas

### Rede
- **Pod CIDR**: `10.42.0.0/16` (customizável)
- **Service CIDR**: `10.43.0.0/16` (customizável)
- **CNI**: Nenhum (preparado para Cilium)
- **ServiceLB**: Ativo (LoadBalancer interno do K3s)

### Componentes Desabilitados
- ❌ **Traefik**: Desabilitado (instalação via Helm)
- ❌ **Flannel**: Desabilitado (Cilium será usado)
- ❌ **Network Policy**: Desabilitado (Cilium gerencia)

### Componentes Ativos
- ✅ **CoreDNS**: DNS interno do cluster
- ✅ **Metrics Server**: Métricas de recursos
- ✅ **Local Path Provisioner**: Storage local
- ✅ **ServiceLB**: Load balancer interno

## 🚨 Troubleshooting

### Problema: Pods em Status Pending
**Causa**: Normal enquanto CNI não estiver instalado (Cilium)
**Solução**: Instalar Cilium como próximo passo

### Problema: kubectl pede credenciais
**Causa**: Contexto do kubeconfig incorreto
**Solução**: 
```bash
# Verificar se o arquivo existe e tem permissões corretas
ls -la ~/.kube/config

# Re-executar o script se necessário
./install-local-k3s.sh
```

### Problema: Erro de porta 6444 ocupada
**Causa**: K3s já está rodando
**Solução**:
```bash
# Parar o serviço
sudo systemctl stop k3s.service

# Ou desinstalar completamente
sudo /usr/local/bin/k3s-uninstall.sh
```

## ⚡ Comandos Úteis

```bash
# Reiniciar K3s
sudo systemctl restart k3s.service

# Parar K3s
sudo systemctl stop k3s.service

# Ver logs em tempo real
sudo journalctl -f -u k3s.service

# Desinstalar K3s completamente
sudo /usr/local/bin/k3s-uninstall.sh

# Backup do kubeconfig
cp ~/.kube/config ~/.kube/config.backup

# Usar kubeconfig original do sistema
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

## 🎯 Próximos Passos

### 1. Instalar Cilium (CNI)
```bash
# Via Helm (recomendado)
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.14.5 \
  --namespace kube-system \
  --set kubeProxyReplacement=strict

# Ou via kubectl (método rápido)
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.14/install/kubernetes/quick-install.yaml
```

### 2. Instalar Traefik (Ingress Controller)
```bash
# Via Helm
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --create-namespace
```

### 3. Verificar Stack Completa
```bash
# Após CNI instalado, pods devem sair de Pending
kubectl get pods -A

# Nó deve ficar Ready
kubectl get nodes

# Verificar conectividade
kubectl run test-pod --image=nginx --restart=Never
kubectl get pod test-pod
kubectl delete pod test-pod
```

## 📚 Recursos e Documentação

### Links Oficiais
- [📖 K3s Documentation](https://docs.k3s.io/)
- [📖 Cilium Documentation](https://docs.cilium.io/en/stable/)
- [📖 Traefik Documentation](https://doc.traefik.io/traefik/)

### Configurações Avançadas
- [🔧 K3s Server Configuration](https://docs.k3s.io/installation/configuration)
- [🔧 Cilium Advanced Features](https://docs.cilium.io/en/stable/gettingstarted/)
- [🔧 Traefik Kubernetes Provider](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)

### Troubleshooting
- [🚨 K3s Common Issues](https://docs.k3s.io/advanced#additional-preparation-for-alpine-linux-setup)
- [🚨 Cilium Troubleshooting](https://docs.cilium.io/en/stable/operations/troubleshooting/)

---

**Status**: ✅ K3s base instalado e configurado  
**Próximo**: 🔄 Instalar Cilium CNI

---