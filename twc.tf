# https://registry.terraform.io/providers/timeweb-cloud/timeweb-cloud/latest/docs
data "twc_presets" "minimal" {
  cpu  = 1
  disk = 1024 * 15
  ram  = 1024
  price_filter {
    from = 100
    to   = 550
  }
  # location = "ru-1" # Enum: "ru-1" "ru-2" "pl-1" "kz-1". Prefer selecting location by network
  # availability_zone # Enum: "spb-1" "spb-2" "spb-3" "spb-4" "msk-1" "nsk-1" "ams-1" "ala-1" "fra-1"
}

data "twc_os" "ubuntu" {
  name    = "ubuntu"
  version = "24.04"
}
