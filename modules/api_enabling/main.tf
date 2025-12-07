# =============================================================================
# API ENABLING MODULE
# =============================================================================
# Enables required GCP APIs for the project
# =============================================================================

resource "google_project_service" "services" {
  for_each = toset(var.services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = var.disable_on_destroy

  timeouts {
    create = "30m"
    update = "40m"
  }
}
