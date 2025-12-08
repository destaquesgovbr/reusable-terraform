# Artifact Registry for Streamlit Docker images
resource "google_artifact_registry_repository" "streamlit" {
  location      = var.region
  repository_id = local.registry_name
  description   = "Docker repository for Streamlit applications"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "2592000s" # 30 days
    }
  }
}
