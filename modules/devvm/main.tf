# =============================================================================
# DEV VM MODULE
# =============================================================================
# Creates a development VM (devvm) with persistent data disk and IAP access
# =============================================================================

locals {
  instance_name  = "${var.devvm_name}-devvm"
  data_disk_name = "${var.devvm_name}-devvm-data"
}
