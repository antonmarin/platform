data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename = "config.cfg"
    content = templatefile(
      "cloud-init.yaml",
      {
        docker-compose-config = file("ingress/docker-compose.yml")
      }
    )
    content_type = "text/cloud-config"
  }
}
