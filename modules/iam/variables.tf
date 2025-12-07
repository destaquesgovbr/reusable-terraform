variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "data_product" {
  description = "Name of the data product"
  type        = string
}

variable "group_team_email" {
  description = "Google Group email for team members (optional)"
  type        = string
  default     = null
}

variable "devvm_sa_name" {
  description = "Account ID for the dev VM service account"
  type        = string
  default     = "sa-w-devvm"
}

variable "devvm_sa_roles" {
  description = "List of roles to grant to the dev VM service account"
  type        = list(string)
  default = [
    "roles/bigquery.user",
    "roles/logging.logWriter",
    "roles/secretmanager.viewer",
    "roles/secretmanager.secretAccessor",
  ]
}

variable "developer_roles" {
  description = "List of roles to grant to developers (group or individual users)"
  type        = list(string)
  default = [
    "roles/bigquery.user",
    "roles/storage.objectViewer",
    "roles/compute.viewer",
    "roles/compute.networkViewer",
    "roles/secretmanager.viewer",
    "roles/logging.viewer",
    "roles/compute.osAdminLogin",
  ]
}

variable "user_emails" {
  description = "List of individual user emails (used when group_team_email is null)"
  type        = list(string)
  default     = []
}
