provider "google" {
  version     = "~> 3.4"
  credentials = var.google_service_account

  project = var.gcp_project
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_project_metadata" "default" {
  metadata = {
    ssh-keys = join("\n", [for user, key in var.ssh_keys : "${user}:${key}"])
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["http-server", "https-server", "ssh-server", "traefik-ui"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-81-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }

  connection {
    type        = "ssh"
    user        = "provisioner"
    private_key = var.provisioner_key
    host        = google_compute_address.vm_static_ip.address
  }

  provisioner "file" {
    source      = "ingress"
    destination = "/home/provisioner"
  }

  provisioner "remote-exec" {
    inline = [
      'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "/home:/home" docker/compose:1.27.4 -f /home/provisioner/ingress/docker-compose.yml up -d',
    ]
  }
}

output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
