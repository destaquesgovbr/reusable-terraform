# =============================================================================
# IAM MODULE
# =============================================================================
# Creates service accounts and IAM bindings for sandbox environments
# =============================================================================

# -----------------------------------------------------------------------------
# Sandbox Service Account
# Used by all sandbox VMs for automatic authentication
# -----------------------------------------------------------------------------

resource "google_service_account" "sandbox" {
  project      = var.project_id
  account_id   = var.sandbox_sa_name
  display_name = "Sandbox VMs Service Account"
  description  = "Service account attached to sandbox VMs for automatic authentication"
}

# -----------------------------------------------------------------------------
# Sandbox SA Roles
# Grant necessary roles to the sandbox service account
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "sandbox_roles" {
  for_each = toset(var.sandbox_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sandbox.email}"
}

# -----------------------------------------------------------------------------
# Sandbox SA Self-Impersonation
# Allow SA to impersonate itself (for chained impersonation)
# -----------------------------------------------------------------------------

resource "google_service_account_iam_member" "sandbox_impersonate_self" {
  service_account_id = google_service_account.sandbox.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.sandbox.email}"
}
