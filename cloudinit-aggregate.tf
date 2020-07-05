data "cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    filename = "config.cfg"
    content = templatefile(
      "cloudinit-config.yml",
      {}
    )
    content_type = "text/cloud-config"
  }

  part {
    filename = "ingress.cfg"
    content = templatefile(
      "ingress/cloudinit.yml",
      {
        docker-compose-config = file("ingress/docker-compose.yml")
      }
    )
    content_type = "text/cloud-config"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "#!/bin/bash\necho bing > /tmp/baz\n"
  }
}
