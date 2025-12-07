# =============================================================================
# IAM BINDINGS
# =============================================================================

# -----------------------------------------------------------------------------
# Group Permissions (when group_team_email is provided)
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "group_roles" {
  for_each = var.group_team_email != null ? toset(var.developer_roles) : []

  project = var.project_id
  role    = each.value
  member  = "group:${var.group_team_email}"
}

# Grant group the custom resourceEditor role
resource "google_project_iam_member" "group_resource_editor" {
  count = var.group_team_email != null ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.resource_editor.id
  member  = "group:${var.group_team_email}"
}

# Allow group to use sandbox SA
resource "google_service_account_iam_member" "group_use_sandbox_sa" {
  count = var.group_team_email != null ? 1 : 0

  service_account_id = google_service_account.sandbox.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${var.group_team_email}"
}

# -----------------------------------------------------------------------------
# Individual User Permissions (when no group is specified)
# Each user gets their own permissions
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "user_roles" {
  for_each = var.group_team_email == null ? {
    for pair in setproduct(var.user_emails, var.developer_roles) :
    "${pair[0]}-${pair[1]}" => { email = pair[0], role = pair[1] }
  } : {}

  project = var.project_id
  role    = each.value.role
  member  = "user:${each.value.email}"
}

# Grant individual users the custom resourceEditor role
resource "google_project_iam_member" "user_resource_editor" {
  for_each = var.group_team_email == null ? toset(var.user_emails) : []

  project = var.project_id
  role    = google_project_iam_custom_role.resource_editor.id
  member  = "user:${each.value}"
}

# Allow individual users to use sandbox SA
resource "google_service_account_iam_member" "user_use_sandbox_sa" {
  for_each = var.group_team_email == null ? toset(var.user_emails) : []

  service_account_id = google_service_account.sandbox.name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:${each.value}"
}
