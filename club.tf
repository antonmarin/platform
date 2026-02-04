resource "twc_project" "club" {
  name        = "Клуб"
  description = "сервисы для своих"
}

resource "twc_vpc" "club-ru" {
  name        = "Club RU network"
  subnet_v4   = "192.168.0.0/24"
  location    = "ru-1"
}

resource "twc_vpc" "club-nl" {
  name        = "Club NL network"
  subnet_v4   = "192.168.0.0/24"
  location    = "nl-1"
}

# resource "twc_server" "vpn-nl" {
#   name         = "NL VPN"
#   os_id        = data.twc_os.ubuntu.id
#   preset_id = data.twc_presets.minimal.id
#   cloud_init = templatefile("cloud-init-docker-machine.yaml", {})
#   project_id = twc_project.club.id
#   local_network {
#     id = twc_vpc.club-nl.id
#   }
# }

resource "ruvds_vps" "my_vps" {
  payment_period = 2 # 1 - тестовый период, 2 - 1 месяц, 3 - 3 месяца, 4 - 6 месяцев, 5 - 1 год
  datacenter_id  = data.ruvds_datacenter.kz-ttc.id
  os_id = data.ruvds_os.ubuntu.id
  cpu = 1 # Cores
  ram = 1.0 # Gb
  drive = 20 # Gb
  drive_tariff_id = 1 #  1 - hdd, 3 - ssd, 10 eu ssd
  tariff_id = 14 # 40 for eu, 22 promo, 14(2.2GHz), 15(3.4GHz), 21 huge
  ip = 1 // should be gt 0
}
