output "kubeconfig_path" {
  value       = var.kubeconfig_path
  description = "Caminho do kubeconfig gerado"
}

output "k3s_version" {
  value       = var.k3s_version
  description = "Versão do K3s instalada"
}

output "node_ip" {
  value       = data.external.local_ip.result["ip"]
  description = "IP do nó do cluster"
}

output "cluster_info" {
  value = {
    cluster_cidr = var.cluster_cidr
    service_cidr = var.service_cidr
    node_ip      = data.external.local_ip.result["ip"]
  }
  description = "Informações do cluster K3s"
}

output "kubectl_config_command" {
  value       = "export KUBECONFIG=${var.kubeconfig_path}"
  description = "Comando para configurar o kubectl"
}
