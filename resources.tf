provider "google" {
  version = "~> 3.4"
  credentials = var.google_service_account

  project = var.gcp_project
  region  = "us-central1"
  zone    = "us-central1-c"
}


resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}


output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}