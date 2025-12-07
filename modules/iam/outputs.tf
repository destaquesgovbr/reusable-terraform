output "sandbox_service_account_email" {
  description = "Email of the sandbox service account"
  value       = google_service_account.sandbox.email
}

output "sandbox_service_account_id" {
  description = "ID of the sandbox service account"
  value       = google_service_account.sandbox.id
}

output "sandbox_service_account_name" {
  description = "Name of the sandbox service account"
  value       = google_service_account.sandbox.name
}

output "resource_editor_role_id" {
  description = "ID of the custom resourceEditor role"
  value       = google_project_iam_custom_role.resource_editor.id
}
