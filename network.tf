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
