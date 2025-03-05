resource "google_compute_network" "main" {
  name                    = "solana-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "solana-subnet"
  ip_cidr_range = "172.16.2.0/24"
  network       = google_compute_network.main.id
  region        = var.gcp_region
}

resource "google_compute_firewall" "salt_minion" {
  name    = "salt-minion-rules"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_ip]
  target_tags   = ["salt-minion"]
} 