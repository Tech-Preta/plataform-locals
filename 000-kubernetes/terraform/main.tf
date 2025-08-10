# K3s Installation Resource
resource "null_resource" "install_k3s" {
  # Triggers para forçar reinstalação quando necessário
  triggers = {
    k3s_version  = var.k3s_version
    node_ip      = local.node_ip
    cluster_cidr = var.cluster_cidr
    service_cidr = var.service_cidr
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command     = <<EOT
      echo 'Instalando K3s localmente...'
      curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version == "latest" ? "" : var.k3s_version} INSTALL_K3S_EXEC="--cluster-cidr ${var.cluster_cidr} --service-cidr ${var.service_cidr} --disable traefik --flannel-backend=none --disable-network-policy" sh -
      NODE_IP=${local.node_ip}
      K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
      USER_KUBECONFIG="$HOME/.kube/config"
      mkdir -p "$HOME/.kube"
      sudo sed "s/127.0.0.1/$NODE_IP/g" "$K3S_KUBECONFIG" > "$USER_KUBECONFIG"
      sed -i "s/name: .*/name: ${var.cluster_name}/g" "$USER_KUBECONFIG"
      sed -i "s/cluster: .*/cluster: ${var.cluster_name}/g" "$USER_KUBECONFIG"
      sed -i "s/context: .*/context: ${var.cluster_name}/g" "$USER_KUBECONFIG"
      sed -i "s/user: default/user: ${var.cluster_name}/g" "$USER_KUBECONFIG"
      sed -i "s/  name: default/  name: ${var.cluster_name}/g" "$USER_KUBECONFIG"
      sudo chown $(id -u):$(id -g) "$USER_KUBECONFIG"
      chmod 600 "$USER_KUBECONFIG"
      sudo chmod 644 "$K3S_KUBECONFIG"
      echo 'K3s instalado e kubeconfig ajustado!'
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Resource para verificar o status do cluster
resource "null_resource" "verify_k3s" {
  depends_on = [null_resource.install_k3s]
  provisioner "local-exec" {
    command     = <<EOT
      echo 'Verificando status do cluster...'
      kubectl get nodes -o wide
      kubectl get pods -A
      echo 'K3s instalado e funcionando!'
      echo 'Kubeconfig disponível em: ${var.kubeconfig_path}'
    EOT
    interpreter = ["bash", "-c"]
  }
}
