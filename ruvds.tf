provider "ruvds" {
  # endpoint = "https://api.ruvds.com/v2"
}

# Get list of datacenters in Russia
# data "ruvds_datacenters" "dcs" {
#   # in_country = "RU",  "CH", "GB", "DE", "NL", "KZ",  "TR" # OVIO has no country
# }
# output "dcs_in_ru" {
#   value = data.ruvds_datacenters.dcs
# }

# Get a data center by its code
data "ruvds_datacenter" "ttc" {
  with_code = "TTC"
}
# output "datacenter_zur1" {
#   value = data.ruvds_datacenter.zur1
# }

# List OSs
# data "ruvds_os_list" "oses" {
#   with_type = "linux"
# }
# output "linux_oses" {
#   value = data.ruvds_os_list.oses
# }

# OS
data "ruvds_os" "ubuntu" {
  with_code = "255-ubuntu-24.04-lts-eng"
}
# output "os_ubuntu_2204" {
#   value = data.ruvds_os.ubuntu_2204
# }

# resource "ruvds_vps" "my_vps" {
#   datacenter_id  = data.ruvds_datacenter.ttc.id
#   cpu = 1 # Cores
#   ram = 1.0 # Gb
#   drive = 20 # Gb
#   os_id = data.ruvds_os.ubuntu_2204.id
#   ip = 0
#   drive_tariff_id = 1 #  1 - hdd, 3 - ssd, 10 eu ssd
#   tariff_id = 14 # 40 for eu, 22 promo, 14(2.2GHz), 15(3.4GHz), 21 huge
#   payment_period = 2 # 1 - тестовый период, 2 - 1 месяц, 3 - 3 месяца, 4 - 6 месяцев, 5 - 1 год
# }
