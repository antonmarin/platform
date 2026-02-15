data "openstack_compute_flavor_v2" "hostvds-1" {
  vcpus = 1
  ram   = 1024
}
data "openstack_compute_flavor_v2" "hostvds-2" {
  vcpus = 1
  ram   = 2048
}
data "openstack_compute_flavor_v2" "hostvds-4" {
  vcpus = 2
  ram   = 4096
}
# data "openstack_compute_flavor_v2" "hostvds-8" {
#   vcpus = 2
#   ram   = 8192
#   disk  = 80  # to diff from highload-2
# }
# data "openstack_compute_flavor_v2" "highload-1" {
#   vcpus = 1
#   ram   = 4096
# }
# data "openstack_compute_flavor_v2" "highload-2" {
#   vcpus = 2
#   ram   = 8192
#   disk  = 50 # to diff from hostvds-8
# }
# output "debug_compute_flavor" {
#   value = data.openstack_compute_flavor_v2.highload-1
# }

data "openstack_images_image_v2" "ubuntu-2404" {
  name = "Ubuntu-24.04-amd64"
}
# output "debug_image" {
#   value = data.openstack_images_image_v2.ubuntu-2404
# }

data "openstack_networking_network_v2" "eu-west2-Internet-24" {
  name = "Internet-29"
  region = "eu-west2" // fr-paris Internet01-32. 01-03,24-29 nok
}
data "openstack_networking_network_v2" "eu-west1-Internet-28" {
  name = "Internet-27"
  region = "eu-west1" // nl-ams Internet01-28. 27-28 nok
}
data "openstack_networking_network_v2" "eu-north2-Internet-01" {
  name = "Internet-16"
  region = "eu-north2" // latvia-riga Internet01-16. 16nok
}
# eu-west1 = nl-ams
# eu-north1, eu-north2 ?
data "openstack_networking_network_v2" "eu-north1b-Internet-06" {
  name = "Internet-06"
  region = "eu-north1b" // fin-helsinki Internet01-08. 06 ok
}
data "openstack_networking_network_v2" "eu-north1b-Internet-07" {
  name = "Internet-07"
  region = "eu-north1b" // fin-helsinki Internet01-08. 06 ok
}
# output "debug_net" {
#   value = data.openstack_networking_network_v2.Internet-01
# }

data "openstack_networking_secgroup_v2" "default" {
  name = "default"
}
data "openstack_networking_secgroup_v2" "allow_all" {
  name = "allow_all"
}

locals {
  burstable-50-05Tb = {
    kind = "standard"
    network_plan = "default-50" // Limited 50Mbps 0.5Tb
  }
  burstable-10000-2Tb = {
    kind = "standard"
    network_plan = "default-10000" // Limited 10Gbps 2Tb
  }
}
