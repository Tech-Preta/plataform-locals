# Plataform Locals - K3s Single Node Installation

O k3s é uma distribuição leve do Kubernetes, ideal para ambientes de desenvolvimento e produção em pequena escala. Este guia cobre a instalação de um cluster K3s em um único nó bare metal, sem dependências de virtualização ou Terraform.

## Pré-requisitos

- **Sistema Operacional**: Ubuntu 20.04+ ou similar (Debian, CentOS, RHEL)
- **RAM**: Mínimo 2GB
- **CPU**: Mínimo 2 vCPUs
- **Disco**: Mínimo 20GB livres
- **Rede**: Conectividade de rede estável
- 
## Instalação
### 1. Preparar o Ambiente

```bash
# Atualizar pacotes
sudo apt update && sudo apt upgrade -y

# Instalar o K3s
curl -sfL https://get.k3s.io | sh -
```

### 1.1 Instalar o k3s com script de customização

```bash
# Esse script instala o K3s com customizações para uso com Cilium e Traefik externo
# Tornar o script executável
chmod +x /home/nataliagranato/Downloads/plataform-locals/000-kubernetes/init/install-local-k3s.sh
# Executar o script com os parâmetros de rede
cd /home/nataliagranato/Downloads/plataform-locals/000-kubernetes/init && ./install-local-k3s.sh 10.42.0.0/16 10.43.0.0/16
```



### 2. Instalando o K3s
```bash
# Instalar o K3s com customizações para uso com Cilium e Traefik externo
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --flannel-backend=none --disable-network-policy" sh -
```
### 3. Configurar o Kubeconfig
```bash
# Obter o IP do nó
NODE_IP=$(hostname -I | awk '{print $1}')
# Configurar o kubeconfig para o usuário atual
K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
USER_KUBECONFIG="$HOME/.kube/config"
sudo sed "s/    server: https:\/\/127.0.0.1:6443/server: https:\/\/$NODE_IP:6443/g" $K3S_KUBECONFIG > $USER_KUBECONFIG
sudo chown $(id -u):$(id -g) $USER_KUBECONFIG
```
### 4. Instalar o Cilium
```bash
# Instalar o Cilium
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.12/install/kubernetes/quick-install.yaml
```
### 5. Instalar o Traefik
```bash
# Instalar o Traefik
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.9/docs/content/reference/dynamic-configuration/kubernetes-crd/traefik.yaml        
```
### 6. Verificar o Status do K3s
```bash
# Verificar o status do K3s
sudo systemctl status k3s.service --no-pager
```
### 7. Verificar o Status do Cilium
```bash
# Verificar o status do Cilium
kubectl get pods -n kube-system -l k8s-app=cilium
```
### 8. Verificar o Status do Traefik
```bash
# Verificar o status do Traefik
kubectl get pods -n kube-system -l app=traefik
kubectl get services -n kube-system -l app=traefik
```

### 9. Acessar o Cluster
```bash
# Copiar o kubeconfig para o usuário atual
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
# Editar o kubeconfig para apontar para o IP do nó
sed -i "s/127.0.0.1/$NODE_IP/g" ~/.kube/config
# Testar o acesso ao cluster
kubectl get nodes
```

## Próximos Passos

- Instalar o Cilium como CNI
- Configurar o Traefik como Ingress Controller
- Instalar CertManager para gerenciar certificados TLS
- Velero para backup e recuperação
- Configurar monitoramento com Prometheus e Grafana
- Implementar logging centralizado com Opensearch
- Configurar CI/CD com ArgoCD
- Implementar segurança com Kyverno
- Gerenciar segredos com Vault
- Expor serviços com Cloudflare Tunnel