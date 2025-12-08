# Secret access management for Streamlit apps
# Note: Secret containers must exist before this module is applied

locals {
  # Flatten app → secrets relationship
  app_secret_pairs = flatten([
    for app_name, app_config in var.streamlit_apps : [
      for secret_id in lookup(app_config, "secrets", []) : {
        app_name  = app_name
        secret_id = secret_id
        sa_email  = lookup(app_config, "dedicated_service_account", false) ? google_service_account.streamlit_app[app_name].email : google_service_account.streamlit_shared.email
      }
    ]
  ])
}

# Grant apps access to their specified secrets
resource "google_secret_manager_secret_iam_member" "streamlit_app_secret_access" {
  for_each = {
    for pair in local.app_secret_pairs : "${pair.app_name}-${pair.secret_id}" => pair
  }

  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.sa_email}"
}
