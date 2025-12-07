# =============================================================================
# FIREWALL RULES
# =============================================================================

# -----------------------------------------------------------------------------
# IAP SSH Access
# Allow SSH access from Google IAP IP range
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "iap_ssh" {
  project     = var.project_id
  name        = var.firewall_iap_name
  network     = google_compute_network.main.id
  description = "Allow SSH and RDP from IAP"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["35.235.240.0/20"] # Google IAP IP range

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  target_tags = ["iap-ssh-enabled"]
}

# -----------------------------------------------------------------------------
# Internal Communication
# Allow all internal traffic within the VPC
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "internal" {
  project     = var.project_id
  name        = var.firewall_internal_name
  network     = google_compute_network.main.id
  description = "Allow internal communication"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = [var.subnet_cidr]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}
