resource "twc_project" "club" {
  name        = "Клуб"
  description = "сервисы для своих"
}

resource "twc_vpc" "club-ru" {
  name      = "Club RU network"
  subnet_v4 = "192.168.0.0/24"
  location  = "ru-1"
}

resource "openstack_compute_instance_v2" "test" {
  name = "Docker machine test"
  // тариф и локация
  flavor_name = data.openstack_compute_flavor_v2.hostvds-1.name
  metadata    = local.burstable-50-05Tb
  region      = data.openstack_networking_network_v2.eu-north2-Internet-01.region
  network {
    name = data.openstack_networking_network_v2.eu-north2-Internet-01.name
  }

  // provision
  image_name = data.openstack_images_image_v2.ubuntu-2404.name
  user_data = templatefile("cloud-init-docker-machine.yaml", {
    ssh_keys = [
      var.ssh_public_key_provision,
      var.ssh_public_key_tunnel
    ]
  })
  security_groups = [data.openstack_networking_secgroup_v2.allow_all.name]
}
output "dm1-ssh" {
  value = "ssh root@${openstack_compute_instance_v2.test.access_ip_v4}"
}

# region docker-machine-2
resource "openstack_compute_instance_v2" "docker-machine2" {
  name = "Docker machine 2"
  // тариф и локация
  flavor_name = data.openstack_compute_flavor_v2.hostvds-1.name
  metadata    = local.burstable-50-05Tb
  region      = data.openstack_networking_network_v2.eu-north1b-Internet-06.region
  network {
    name = data.openstack_networking_network_v2.eu-north1b-Internet-06.name
  }

  // provision
  image_name = data.openstack_images_image_v2.ubuntu-2404.name
  user_data = templatefile("cloud-init-docker-machine.yaml", {
    ssh_keys = [
      var.ssh_public_key_provision,
      var.ssh_public_key_tunnel
    ]
  })
  security_groups = [data.openstack_networking_secgroup_v2.allow_all.name]
}
output "dm2-ssh" {
  value = "ssh root@${openstack_compute_instance_v2.docker-machine2.access_ip_v4}"
}
# endregion

# region beget-test
# endregion
