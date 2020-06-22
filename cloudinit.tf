data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false


  part {
    filename = "ingress.cfg"
    content = templatefile(
      "cloudinit-ingress.yml",
      {
        docker-compose-config = file("ingress/docker-compose.yml")
      }
    )
    content_type = "text/cloud-config"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "echo 123 > ~/123.txt"
  }
}
