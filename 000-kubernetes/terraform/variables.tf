variable "kubeconfig_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Caminho do kubeconfig"
}

variable "cluster_cidr" {
  type        = string
  default     = "10.42.0.0/16"
  description = "CIDR para o cluster"

  validation {
    condition     = can(cidrhost(var.cluster_cidr, 0))
    error_message = "O cluster_cidr deve ser um CIDR válido."
  }
}

variable "service_cidr" {
  type        = string
  default     = "10.43.0.0/16"
  description = "CIDR para os serviços"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "O service_cidr deve ser um CIDR válido."
  }
}

variable "k3s_version" {
  type        = string
  default     = "v1.33.0+k3s1"
  description = "Versão do K3s a ser instalada"
}

variable "disable_components" {
  type        = list(string)
  default     = ["traefik"]
  description = "Componentes do K3s para desabilitar"
}

variable "flannel_backend" {
  type        = string
  default     = "none"
  description = "Backend do Flannel (none para usar CNI customizado)"
}

variable "cluster_name" {
  type        = string
  default     = "techpreta"
  description = "Nome do cluster/contexto no kubeconfig"
}
