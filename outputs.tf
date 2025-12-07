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

output "sandbox_service_account_email" {
  description = "Email of the sandbox service account"
  value       = var.enable_iam ? module.iam[0].sandbox_service_account_email : null
}

output "sandbox_service_account_id" {
  description = "ID of the sandbox service account"
  value       = var.enable_iam ? module.iam[0].sandbox_service_account_id : null
}

# =============================================================================
# SANDBOX OUTPUTS
# =============================================================================

output "sandbox_instances" {
  description = "Map of sandbox instance details"
  value = {
    for name, sandbox in module.sandbox : name => {
      instance_name = sandbox.instance_name
      instance_id   = sandbox.instance_id
      zone          = sandbox.zone
      ssh_command   = sandbox.ssh_command
    }
  }
}

output "sandbox_ssh_commands" {
  description = "SSH commands to connect to each sandbox via IAP"
  value = {
    for name, sandbox in module.sandbox : name => sandbox.ssh_command
  }
}
