variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "data_product" {
  description = "Name of the data product (used for naming)"
  type        = string
}

variable "github_organization" {
  description = "GitHub organization name for Workload Identity"
  type        = string
}

variable "github_actions_sa_email" {
  description = "GitHub Actions service account email (for Workload Identity)"
  type        = string
}

variable "streamlit_apps" {
  description = "Map of Streamlit applications to deploy"
  type = map(object({
    repository                = string
    description               = string
    resource_tier             = string # "small", "medium", "large"
    dedicated_service_account = optional(bool, false)
    secrets                   = optional(list(string), [])
    min_instances             = optional(number, 0)
    max_instances             = optional(number)
    port                      = optional(number, 8501)
    env_vars                  = optional(map(string), {})
    secret_env_vars           = optional(map(string), {}) # Map of ENV_NAME => secret_id from Secret Manager
    initial_image             = optional(string)          # Docker image for initial deployment
  }))
  default = {}
}

variable "artifact_registry_name" {
  description = "Name for the Artifact Registry repository"
  type        = string
  default     = null # Will default to {data_product}-streamlit
}

variable "artifact_registry_keep_count" {
  description = "Number of most recent versions of each image kept by the Artifact Registry cleanup policy (KEEP only: nothing is deleted by age)"
  type        = number
  default     = 30

  validation {
    condition     = var.artifact_registry_keep_count >= 1
    error_message = "artifact_registry_keep_count must be at least 1."
  }
}

variable "shared_sa_roles" {
  description = "IAM roles for the shared Streamlit service account"
  type        = list(string)
  default = [
    "roles/storage.objectViewer",
  ]
}
