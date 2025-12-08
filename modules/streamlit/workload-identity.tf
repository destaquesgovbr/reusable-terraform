# Workload Identity bindings for app repositories
# Allows GitHub Actions from app repos to deploy their apps

resource "google_service_account_iam_member" "github_actions_workload_identity_streamlit_apps" {
  for_each = var.streamlit_apps

  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.github_actions_sa_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${var.github_organization}/${each.value.repository}"
}

data "google_project" "project" {
  project_id = var.project_id
}
