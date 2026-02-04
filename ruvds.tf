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
data "ruvds_datacenter" "kz-ttc" {
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

resource "ruvds_ssh" "my_key" {
  name = "tony book"
  # public_key = "ssh-ed25519 AAAAC**...." place real here
}
