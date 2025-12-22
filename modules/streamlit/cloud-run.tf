# Cloud Run services for each Streamlit app
resource "google_cloud_run_v2_service" "streamlit_app" {
  for_each = var.streamlit_apps

  name     = "streamlit-${each.key}"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    # Service account (shared or dedicated)
    service_account = lookup(each.value, "dedicated_service_account", false) ? google_service_account.streamlit_app[each.key].email : google_service_account.streamlit_shared.email

    # Scaling configuration
    scaling {
      min_instance_count = lookup(each.value, "min_instances", 0)
      max_instance_count = lookup(each.value, "max_instances", local.resource_tiers[each.value.resource_tier].max_instances)
    }

    # Container configuration
    containers {
      # Image updated by CI/CD - starts with placeholder until first deploy
      image = coalesce(each.value.initial_image, "us-docker.pkg.dev/cloudrun/container/hello")

      # Resource limits based on tier
      resources {
        limits = {
          cpu    = local.resource_tiers[each.value.resource_tier].cpu
          memory = local.resource_tiers[each.value.resource_tier].memory
        }
        cpu_idle = true
      }

      # Port configuration
      ports {
        container_port = lookup(each.value, "port", 8501)
        name           = "http1"
      }

      # Startup probe (Streamlit health endpoint)
      startup_probe {
        timeout_seconds   = 10
        period_seconds    = 10
        failure_threshold = 5
        http_get {
          path = "/_stcore/health"
          port = lookup(each.value, "port", 8501)
        }
      }

      # Liveness probe
      liveness_probe {
        timeout_seconds = 5
        period_seconds  = 30
        http_get {
          path = "/_stcore/health"
          port = lookup(each.value, "port", 8501)
        }
      }

      # Environment variables
      dynamic "env" {
        for_each = lookup(each.value, "env_vars", {})
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    # Request timeout
    timeout = "300s"

    # Execution environment (Gen2 for better performance)
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }
}

# Public access for all apps
resource "google_cloud_run_v2_service_iam_member" "streamlit_app_public" {
  for_each = var.streamlit_apps

  location = google_cloud_run_v2_service.streamlit_app[each.key].location
  name     = google_cloud_run_v2_service.streamlit_app[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
