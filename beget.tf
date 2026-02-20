# resource "beget_ssh_key" "provisioner" {
#   name = "provisioner"
#   public_key = var.ssh_public_key_provision
# }
# resource "beget_ssh_key" "tunnel" {
#   name = "tunnel"
#   public_key = var.ssh_public_key_tunnel
# }

data "beget_private_networks" "all" {}

# data "beget_regions" "regions_list" {}
data "beget_region" "ru1" {
  id = "ru1"
}
data "beget_region" "ru2" {
  id = "ru2"
}
data "beget_region" "kz1" {
  id = "kz1"
}
data "beget_region" "lv1" {
  id = "lv1"
}
# output "reg" {
#   value = data.beget_region.lv1
# }


# data "beget_configurations" "normal" {
#   region = data.beget_region.lv1.id
#   group = "normal_cpu"
#   # group = "high_cpu"
#   # only_available
# #   kz1_prime_v4/lv1_prime_v4 - 660/m
# }
# output "configuration_ids" {
#   value = data.beget_configurations.normal
# }
data "beget_configuration" "lv_prime" {
  id = "lv1_prime_v4"
}
# output "lv_p" {
#   value = data.beget_configuration.lv_prime
# }


# data "beget_softwares" "software_list" {}
# output "soft" {
#   value = data.beget_softwares.software_list
# }
data "beget_software" "ubuntu" {
  slug = "ubuntu-24-04"
}
