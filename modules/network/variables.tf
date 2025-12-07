variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_name" {
  description = "Name for the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name for the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.128.0.0/20"
}

variable "router_name" {
  description = "Name for the Cloud Router"
  type        = string
}

variable "nat_name" {
  description = "Name for the Cloud NAT"
  type        = string
}

variable "firewall_iap_name" {
  description = "Name for the IAP firewall rule"
  type        = string
}

variable "firewall_internal_name" {
  description = "Name for the internal firewall rule"
  type        = string
}
