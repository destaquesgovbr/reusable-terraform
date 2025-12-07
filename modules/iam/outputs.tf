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
