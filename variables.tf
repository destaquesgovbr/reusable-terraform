# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "data_product" {
  description = "Name of the data product (used for naming resources)"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "southamerica-east1"
}

variable "zone" {
  description = "GCP zone for compute resources"
  type        = string
  default     = "southamerica-east1-a"
}

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================

variable "group_team_email" {
  description = "Google Group email for team members (optional - if not set, permissions are per-user)"
  type        = string
  default     = null
}

# =============================================================================
# MODULE TOGGLES
# =============================================================================

variable "enable_apis" {
  description = "Enable the api_enabling module"
  type        = bool
  default     = true
}

variable "enable_network" {
  description = "Enable the network module"
  type        = bool
  default     = true
}

variable "enable_iam" {
  description = "Enable the iam module"
  type        = bool
  default     = true
}

# =============================================================================
# SANDBOX CONFIGURATION
# =============================================================================

variable "sandbox" {
  description = "Sandbox configuration for development VMs"
  type = object({
    sandboxes = optional(map(object({
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
    })), {})
  })
  default = {
    sandboxes = {}
  }
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "network_name" {
  description = "Name for the VPC network"
  type        = string
  default     = null # Will default to {data_product}-sandbox-network
}

variable "subnet_cidr" {
  description = "CIDR range for the main subnet"
  type        = string
  default     = "10.128.0.0/20"
}
