# Shared service account for Streamlit apps (default)
resource "google_service_account" "streamlit_shared" {
  account_id   = "streamlit-shared"
  display_name = "Shared Service Account for Streamlit Apps"
  description  = "Used by Streamlit apps that don't require dedicated service accounts"
}

# Grant shared SA the specified roles
resource "google_project_iam_member" "streamlit_shared_roles" {
  for_each = toset(var.shared_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.streamlit_shared.email}"
}

# Dedicated service accounts (when needed)
resource "google_service_account" "streamlit_app" {
  for_each = {
    for k, v in var.streamlit_apps : k => v
    if lookup(v, "dedicated_service_account", false)
  }

  account_id   = "streamlit-${each.key}"
  display_name = "Service Account for Streamlit app: ${each.key}"
  description  = "Dedicated SA for ${var.streamlit_apps[each.key].repository}"
}
