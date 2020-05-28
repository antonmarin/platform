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

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "vpc_network_ssh" {
  name           = "ssh-access"
  network        = google_compute_network.vpc_network.name
  enable_logging = true

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["ssh-server"]
}

resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["http-server", "https-server", "ssh-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }

  metadata = {
    user-data = data.template_cloudinit_config.config.rendered
  }
}


output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
