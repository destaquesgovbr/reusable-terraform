# =============================================================================
# EXAMPLE: DestaquesGovBR Development Environment
# =============================================================================
# This example shows how to use the reusable-terraform module to provision
# development VMs for the DestaquesGovBR project.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  # Uncomment to use remote state
  # backend "gcs" {
  #   bucket = "inspire-7-finep-terraform-state"
  #   prefix = "reusable-terraform/example"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------------------------------------------------
# Module Usage
# -----------------------------------------------------------------------------

module "dev_environment" {
  source = "../../"

  project_id   = var.project_id
  data_product = var.data_product
  region       = var.region
  zone         = var.zone

  # Google Group is optional - using individual users
  # group_team_email = "devs@destaquesgovbr.com"

  # Module toggles
  enable_apis    = true
  enable_network = true
  enable_iam     = true

  # Dev VM configuration
  devvm = {
    devvms = var.devvms
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "network_name" {
  description = "Name of the created VPC"
  value       = module.dev_environment.network_name
}

output "devvm_ssh_commands" {
  description = "SSH commands to connect to each dev VM"
  value       = module.dev_environment.devvm_ssh_commands
}

output "devvm_service_account" {
  description = "Email of the dev VM service account"
  value       = module.dev_environment.devvm_service_account_email
}
