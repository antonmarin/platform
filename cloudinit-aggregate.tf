data "cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    filename = "config.cfg"
    content = templatefile(
      "cloud-init.cfg",
      {}
    )
    content_type = "text/cloud-config"
  }
}
