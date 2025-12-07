# =============================================================================
# IAP TUNNEL ACCESS
# =============================================================================
# Configures who can access this VM via IAP tunnel (SSH)
# =============================================================================

# -----------------------------------------------------------------------------
# Owner Access (when owner_email is set)
# Only the specified user can access via IAP
# -----------------------------------------------------------------------------

resource "google_iap_tunnel_instance_iam_member" "owner_access" {
  count = var.devvm_config.instance.owner_email != null ? 1 : 0

  project  = var.project_id
  zone     = var.zone
  instance = google_compute_instance.devvm.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:${var.devvm_config.instance.owner_email}"
}

# -----------------------------------------------------------------------------
# Group Access (when group_team_email is set and no owner)
# The entire group can access via IAP (shared dev VM)
# -----------------------------------------------------------------------------

resource "google_iap_tunnel_instance_iam_member" "group_access" {
  count = var.group_team_email != null && var.devvm_config.instance.owner_email == null ? 1 : 0

  project  = var.project_id
  zone     = var.zone
  instance = google_compute_instance.devvm.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "group:${var.group_team_email}"
}
