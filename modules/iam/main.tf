# =============================================================================
# IAM MODULE
# =============================================================================
# Creates service accounts and IAM bindings for dev VM environments
# =============================================================================

# -----------------------------------------------------------------------------
# Dev VM Service Account
# Used by all dev VMs for automatic authentication
# -----------------------------------------------------------------------------

resource "google_service_account" "devvm" {
  project      = var.project_id
  account_id   = var.devvm_sa_name
  display_name = "Dev VMs Service Account"
  description  = "Service account attached to dev VMs for automatic authentication"
}

# -----------------------------------------------------------------------------
# Dev VM SA Roles
# Grant necessary roles to the dev VM service account
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "devvm_roles" {
  for_each = toset(var.devvm_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.devvm.email}"
}

# -----------------------------------------------------------------------------
# Dev VM SA Self-Impersonation
# Allow SA to impersonate itself (for chained impersonation)
# -----------------------------------------------------------------------------

resource "google_service_account_iam_member" "devvm_impersonate_self" {
  service_account_id = google_service_account.devvm.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.devvm.email}"
}
