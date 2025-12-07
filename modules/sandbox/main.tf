# =============================================================================
# SANDBOX MODULE
# =============================================================================
# Creates a development VM (sandbox) with persistent data disk and IAP access
# =============================================================================

locals {
  instance_name  = "${var.sandbox_name}-sandbox"
  data_disk_name = "${var.sandbox_name}-sandbox-data"
}
