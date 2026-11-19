# Artifact Registry for Streamlit Docker images
resource "google_artifact_registry_repository" "streamlit" {
  location      = var.region
  repository_id = local.registry_name
  description   = "Docker repository for Streamlit applications"
  format        = "DOCKER"

  # KEEP only, with no DELETE policy: Artifact Registry deletes nothing in this
  # repository, whatever the age or the number of versions. Versions beyond the
  # 30 most recent are NOT pruned. The KEEP rule only matters if a DELETE policy
  # is added later: it then protects the 30 most recent versions of each image
  # from that DELETE. This is the same setup as the other Docker repositories of
  # the destaquesgovbr project.
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
      keep_count = 30
    }
  }
}
