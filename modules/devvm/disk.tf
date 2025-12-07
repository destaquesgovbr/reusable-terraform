# =============================================================================
# PERSISTENT DATA DISK
# =============================================================================
# This disk persists data across VM recreations
# =============================================================================

resource "google_compute_disk" "data" {
  project = var.project_id
  name    = local.data_disk_name
  type    = var.devvm_config.instance.data_disk_type
  size    = var.devvm_config.instance.data_disk_size_gb
  zone    = var.zone

  labels = {
    devvm      = var.devvm_name
    owner      = replace(var.devvm_config.instance.owner_email, "/[@.]/", "-")
    managed_by = "terraform"
  }

  # IMPORTANT: Prevent accidental deletion of data
  lifecycle {
    prevent_destroy = false # Set to true in production!
  }
}
