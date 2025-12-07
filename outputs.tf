# =============================================================================
# NETWORK OUTPUTS
# =============================================================================

output "network_id" {
  description = "The ID of the VPC network"
  value       = var.enable_network ? module.network[0].network_id : null
}

output "network_name" {
  description = "The name of the VPC network"
  value       = var.enable_network ? module.network[0].network_name : null
}

output "subnetwork_id" {
  description = "The ID of the subnet"
  value       = var.enable_network ? module.network[0].subnetwork_id : null
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "devvm_service_account_email" {
  description = "Email of the dev VM service account"
  value       = var.enable_iam ? module.iam[0].devvm_service_account_email : null
}

output "devvm_service_account_id" {
  description = "ID of the dev VM service account"
  value       = var.enable_iam ? module.iam[0].devvm_service_account_id : null
}

# =============================================================================
# DEV VM OUTPUTS
# =============================================================================

output "devvm_instances" {
  description = "Map of dev VM instance details"
  value = {
    for name, devvm in module.devvm : name => {
      instance_name = devvm.instance_name
      instance_id   = devvm.instance_id
      zone          = devvm.zone
      ssh_command   = devvm.ssh_command
    }
  }
}

output "devvm_ssh_commands" {
  description = "SSH commands to connect to each dev VM via IAP"
  value = {
    for name, devvm in module.devvm : name => devvm.ssh_command
  }
}
