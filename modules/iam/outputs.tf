output "devvm_service_account_email" {
  description = "Email of the dev VM service account"
  value       = google_service_account.devvm.email
}

output "devvm_service_account_id" {
  description = "ID of the dev VM service account"
  value       = google_service_account.devvm.id
}

output "devvm_service_account_name" {
  description = "Name of the dev VM service account"
  value       = google_service_account.devvm.name
}

output "resource_editor_role_id" {
  description = "ID of the custom resourceEditor role"
  value       = google_project_iam_custom_role.resource_editor.id
}

output "github_actions_sa_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "github_actions_sa_id" {
  description = "ID of the GitHub Actions service account"
  value       = google_service_account.github_actions.id
}
