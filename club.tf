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

resource "twc_server" "vpn-nl" {
  name         = "NL VPN"
  os_id        = data.twc_os.ubuntu.id
  preset_id = data.twc_presets.minimal.id
  cloud_init = templatefile("cloud-init-docker-machine.yaml", {})
  project_id = twc_project.club.id
  local_network {
    id = twc_vpc.club-nl.id
  }
}
