variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "inspire-7-finep"
}

variable "data_product" {
  description = "Name of the data product"
  type        = string
  default     = "destaquesgovbr"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "southamerica-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "southamerica-east1-a"
}

variable "sandboxes" {
  description = "Map of sandbox configurations"
  type = map(object({
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
  }))
  default = {}
}
