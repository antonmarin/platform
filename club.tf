resource "twc_project" "club" {
  name        = "Клуб"
  description = "сервисы для своих"
}

resource "twc_vpc" "club-ru" {
  name      = "Club RU network"
  subnet_v4 = "192.168.0.0/24"
  location  = "ru-1"
}

# region beget-test
# endregion
