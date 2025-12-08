# =============================================================================
# STREAMLIT MODULE
# =============================================================================
# Manages Streamlit applications on Cloud Run
# =============================================================================

locals {
  registry_name = var.artifact_registry_name != null ? var.artifact_registry_name : "${var.data_product}-streamlit"

  # Resource tier definitions
  resource_tiers = {
    small = {
      cpu           = "1"
      memory        = "512Mi"
      max_instances = 3
    }
    medium = {
      cpu           = "1"
      memory        = "1Gi"
      max_instances = 5
    }
    large = {
      cpu           = "2"
      memory        = "2Gi"
      max_instances = 10
    }
  }
}
