variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "data_product" {
  description = "Name of the data product"
  type        = string
}

variable "sandbox_name" {
  description = "Name of the sandbox (used as prefix for resources)"
  type        = string
}

variable "sandbox_config" {
  description = "Configuration for this sandbox"
  type = object({
    instance = object({
      machine_type      = string
      owner_email       = string
      image             = optional(string, "ubuntu-os-cloud/ubuntu-2204-lts")
      boot_disk_type    = optional(string, "pd-standard")
      boot_disk_size_gb = optional(number, 50)
      data_disk_type    = optional(string, "pd-standard")
      data_disk_size_gb = optional(number, 100)
      subnetwork        = optional(string)
    })
    bucket = optional(object({
      bucket_public_access_prevention = optional(string, "enforced")
    }))
  })
}

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "subnetwork_id" {
  description = "ID of the subnet"
  type        = string
}

variable "sandbox_service_account_email" {
  description = "Email of the sandbox service account"
  type        = string
}

variable "group_team_email" {
  description = "Google Group email for shared access (optional)"
  type        = string
  default     = null
}

# =============================================================================
# AUTO-SHUTDOWN CONFIGURATION
# =============================================================================

variable "auto_shutdown_enabled" {
  description = "Enable automatic shutdown of VMs"
  type        = bool
  default     = true
}

variable "auto_shutdown_schedule" {
  description = "Cron schedule for auto-shutdown (default: 19:00 Sao Paulo time)"
  type        = string
  default     = "0 19 * * *"
}

variable "auto_start_enabled" {
  description = "Enable automatic start of VMs in the morning"
  type        = bool
  default     = false
}

variable "auto_start_schedule" {
  description = "Cron schedule for auto-start (default: 08:00 Sao Paulo time, weekdays)"
  type        = string
  default     = "0 8 * * 1-5"
}

variable "schedule_timezone" {
  description = "Timezone for schedules"
  type        = string
  default     = "America/Sao_Paulo"
}
