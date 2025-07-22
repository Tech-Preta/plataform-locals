# Obtém o IP local da máquina onde o Terraform está sendo executado
locals {
  node_ip = data.external.local_ip.result["ip"]
}
