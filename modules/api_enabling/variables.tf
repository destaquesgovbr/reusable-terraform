variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "services" {
  description = "List of APIs to enable"
  type        = list(string)
  default = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iap.googleapis.com",
  ]
}

variable "disable_on_destroy" {
  description = "Whether to disable APIs on destroy (recommended: false)"
  type        = bool
  default     = false
}
