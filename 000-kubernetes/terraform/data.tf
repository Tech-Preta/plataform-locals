data "external" "local_ip" {
  program = ["bash", "-c", "hostname -I | awk '{print $1}' | xargs -I{} echo '{\"ip\":\"{}\"}'"]
}

