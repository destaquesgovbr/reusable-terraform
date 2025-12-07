# =============================================================================
# CUSTOM ROLES
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Editor Custom Role
# Allows developers to start/stop VMs without full compute admin
# -----------------------------------------------------------------------------

resource "google_project_iam_custom_role" "resource_editor" {
  project     = var.project_id
  role_id     = "resourceEditor"
  title       = "Resource Editor"
  description = "Allows start/stop/suspend/resume of compute instances and basic resource listing"

  permissions = [
    "compute.instances.stop",
    "compute.instances.start",
    "compute.instances.suspend",
    "compute.instances.resume",
    "compute.instances.reset",
    "storage.buckets.list",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
  ]
}
