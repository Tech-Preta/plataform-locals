#!/bin/bash
set -e

# Argumentos opcionais: cluster-cidr, service-cidr
CLUSTER_CIDR="${1:-10.42.0.0/16}"
SERVICE_CIDR="${2:-10.43.0.0/16}"

# Instala o K3s com customizações para uso com Cilium e Traefik externo (sem --cluster-name)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--cluster-cidr $CLUSTER_CIDR --service-cidr $SERVICE_CIDR --disable traefik --flannel-backend=none --disable-network-policy" sh -

# Obtém o IP do nó (pega o primeiro IP não localhost)
NODE_IP=$(hostname -I | awk '{print $1}')

# Caminho do kubeconfig gerado pelo K3s
K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

# Caminho do kubeconfig para o usuário atual
USER_KUBECONFIG="$HOME/.kube/config"
mkdir -p "$HOME/.kube"

# Faz o replace do endereço no kubeconfig e copia para o usuário
sudo sed "s/127.0.0.1/$NODE_IP/g" "$K3S_KUBECONFIG" > "$USER_KUBECONFIG"

# Altera o nome do cluster no kubeconfig para 'nataliagranato'
sed -i 's/name: .*/name: nataliagranato/g' "$USER_KUBECONFIG"
sed -i 's/cluster: .*/cluster: nataliagranato/g' "$USER_KUBECONFIG"
sed -i 's/context: .*/context: nataliagranato/g' "$USER_KUBECONFIG"
sed -i 's/user: default/user: nataliagranato/g' "$USER_KUBECONFIG"
sed -i 's/  name: default/  name: nataliagranato/g' "$USER_KUBECONFIG"

sudo chown $(id -u):$(id -g) "$USER_KUBECONFIG"
chmod 600 "$USER_KUBECONFIG"

# Adiciona o usuário ao grupo k3s, se existir
if getent group k3s >/dev/null; then
    sudo usermod -aG k3s $(id -un)
    echo "Usuário $(id -un) adicionado ao grupo k3s."
fi

# Garante permissão de leitura do kubeconfig original para o usuário
sudo chmod 644 "$K3S_KUBECONFIG"

echo "K3s instalado com sucesso!"
echo "Kubeconfig ajustado para o IP: $NODE_IP"
echo "Use: kubectl get nodes para testar."
echo "Se precisar rodar comandos do K3s server, utilize: sudo k3s server"
echo "Se quiser usar o kubeconfig original, exporte: export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
echo "(Reabra o terminal para que o grupo k3s tenha efeito, se necessário.)"
