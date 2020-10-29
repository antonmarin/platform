resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "vpc_network_ssh" {
  name    = "ssh-access"
  network = google_compute_network.vpc_network.name
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["ssh-server"]
}

resource "google_compute_firewall" "vpc_port_http" {
  name    = "http-server"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http-server"]
}
resource "google_compute_firewall" "vpc_port_https" {
  name    = "https-server"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["https-server"]
}

resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}


resource "google_compute_firewall" "vpc_port_traefik_ui" {
  name    = "traefik-ui"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["traefik-ui"]
}
