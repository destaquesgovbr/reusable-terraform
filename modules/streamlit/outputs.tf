output "artifact_registry_id" {
  description = "ID of the Artifact Registry repository"
  value       = google_artifact_registry_repository.streamlit.id
}

output "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.streamlit.repository_id
}

output "shared_service_account_email" {
  description = "Email of the shared Streamlit service account"
  value       = google_service_account.streamlit_shared.email
}

output "app_service_accounts" {
  description = "Map of app names to their dedicated service account emails"
  value = {
    for k, v in google_service_account.streamlit_app : k => v.email
  }
}

output "app_urls" {
  description = "Map of app names to their Cloud Run URLs"
  value = {
    for k, v in google_cloud_run_v2_service.streamlit_app : k => v.uri
  }
}

output "app_service_names" {
  description = "Map of app names to their Cloud Run service names"
  value = {
    for k, v in google_cloud_run_v2_service.streamlit_app : k => v.name
  }
}
