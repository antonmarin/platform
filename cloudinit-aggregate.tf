data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename = "config.cfg"
    content = templatefile(
      "cloud-init.yaml",
      {
        platform_apps = var.platform_apps
      }
    )
    content_type = "text/cloud-config"
  }
}
