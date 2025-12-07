# =============================================================================
# INSTANCE SCHEDULE - AUTO SHUTDOWN/START
# =============================================================================
# Automatically stops VMs at specified time to save costs
# =============================================================================

resource "google_compute_resource_policy" "auto_shutdown" {
  count = var.auto_shutdown_enabled ? 1 : 0

  project     = var.project_id
  name        = "${local.instance_name}-schedule"
  region      = var.region
  description = "Auto-shutdown schedule for ${local.instance_name}"

  instance_schedule_policy {
    time_zone = var.schedule_timezone

    vm_stop_schedule {
      schedule = var.auto_shutdown_schedule
    }

    dynamic "vm_start_schedule" {
      for_each = var.auto_start_enabled ? [1] : []
      content {
        schedule = var.auto_start_schedule
      }
    }
  }
}
