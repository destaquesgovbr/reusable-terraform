# =============================================================================
# COMPUTE INSTANCE
# =============================================================================

resource "google_compute_instance" "sandbox" {
  project      = var.project_id
  name         = local.instance_name
  machine_type = var.sandbox_config.instance.machine_type
  zone         = var.zone

  tags = ["iap-ssh-enabled"]

  labels = {
    sandbox    = var.sandbox_name
    owner      = replace(var.sandbox_config.instance.owner_email, "/[@.]/", "-")
    managed_by = "terraform"
  }

  # Boot disk
  boot_disk {
    initialize_params {
      image = var.sandbox_config.instance.image
      size  = var.sandbox_config.instance.boot_disk_size_gb
      type  = var.sandbox_config.instance.boot_disk_type
    }
  }

  # Attach persistent data disk
  attached_disk {
    source      = google_compute_disk.data.self_link
    device_name = "data-disk"
    mode        = "READ_WRITE"
  }

  # Network interface - NO external IP (IAP only)
  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    # No access_config = no public IP
  }

  # Service account for automatic authentication
  service_account {
    email  = var.sandbox_service_account_email
    scopes = ["cloud-platform"]
  }

  # Disable OS Login to avoid external user permission issues
  # SSH keys will be managed automatically by gcloud
  metadata = {
    enable-oslogin = "FALSE"
  }

  # Startup script to mount data disk
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Mount data disk if not already mounted
    DATA_DISK="/dev/disk/by-id/google-data-disk"
    MOUNT_POINT="/mnt/data"

    if [ ! -d "$MOUNT_POINT" ]; then
      mkdir -p "$MOUNT_POINT"
    fi

    # Check if disk needs formatting
    if ! blkid "$DATA_DISK" > /dev/null 2>&1; then
      echo "Formatting data disk..."
      mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DATA_DISK"
    fi

    # Mount if not already mounted
    if ! mountpoint -q "$MOUNT_POINT"; then
      mount -o discard,defaults "$DATA_DISK" "$MOUNT_POINT"
      echo "$DATA_DISK $MOUNT_POINT ext4 discard,defaults,nofail 0 2" >> /etc/fstab
    fi

    # Set permissions
    chmod 755 "$MOUNT_POINT"

    echo "Data disk mounted at $MOUNT_POINT"
  EOF

  # Allow stopping for updates
  allow_stopping_for_update = true

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  # Attach auto-shutdown schedule if enabled
  resource_policies = var.auto_shutdown_enabled ? [google_compute_resource_policy.auto_shutdown[0].self_link] : []

  lifecycle {
    ignore_changes = [
      # Ignore changes to metadata that might be added by GCP
      metadata["ssh-keys"],
    ]
  }
}
