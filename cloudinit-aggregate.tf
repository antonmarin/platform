data "cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    filename = "config.cfg"
    content = templatefile(
      "cloudinit.yml",
      {}
    )
    content_type = "text/cloud-config"
  }
}
