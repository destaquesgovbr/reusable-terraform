# Artifact Registry for Streamlit Docker images
resource "google_artifact_registry_repository" "streamlit" {
  location      = var.region
  repository_id = local.registry_name
  description   = "Docker repository for Streamlit applications"
  format        = "DOCKER"

  # Keep the N most recent versions of each image (package). There is no DELETE
  # policy on purpose: with only KEEP policies, Artifact Registry never deletes
  # anything, so an image still referenced by a Cloud Run revision cannot be
  # removed just because of its age.
  #
  # The previous policy (DELETE, tag_state = "ANY", older_than = 30 days)
  # deleted every image older than 30 days, including the ones serving Cloud
  # Run. A Streamlit app that is not rebuilt for a month then loses its image,
  # and any new revision (an env var change, for example) fails with "Image ...
  # not found" until the app is rebuilt.
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.artifact_registry_keep_count
    }
  }
}
