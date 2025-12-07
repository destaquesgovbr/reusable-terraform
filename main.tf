# =============================================================================
# REUSABLE TERRAFORM MODULE - GCP Development Environments
# =============================================================================
#
# This module provisions development VM environments on GCP including:
# - API enablement
# - VPC networking with IAP access
# - Service accounts and IAM
# - Development VMs (devvms)
#
# =============================================================================

# -----------------------------------------------------------------------------
# API ENABLING
# -----------------------------------------------------------------------------

module "api_enabling" {
  count  = var.enable_apis ? 1 : 0
  source = "./modules/api_enabling"

  project_id = var.project_id
  services   = local.required_apis
}

# -----------------------------------------------------------------------------
# NETWORK
# -----------------------------------------------------------------------------

module "network" {
  count  = var.enable_network ? 1 : 0
  source = "./modules/network"

  project_id   = var.project_id
  region       = var.region
  network_name = local.network_name
  subnet_name  = local.subnet_name
  subnet_cidr  = var.subnet_cidr
  router_name  = local.router_name
  nat_name     = local.nat_name

  firewall_iap_name      = local.firewall_iap_name
  firewall_internal_name = local.firewall_internal_name

  depends_on = [module.api_enabling]
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

module "iam" {
  count  = var.enable_iam ? 1 : 0
  source = "./modules/iam"

  project_id       = var.project_id
  data_product     = var.data_product
  group_team_email = var.group_team_email

  devvm_sa_name   = local.devvm_sa_name
  devvm_sa_roles  = local.devvm_sa_roles
  developer_roles = local.developer_roles

  # Individual user emails from devvm definitions
  user_emails = [for name, config in var.devvm.devvms : config.instance.owner_email]

  depends_on = [module.api_enabling]
}

# -----------------------------------------------------------------------------
# DEV VMs
# -----------------------------------------------------------------------------

module "devvm" {
  for_each = var.devvm.devvms
  source   = "./modules/devvm"

  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  data_product = var.data_product

  devvm_name   = each.key
  devvm_config = each.value

  # Network configuration
  network_id    = var.enable_network ? module.network[0].network_id : null
  subnetwork_id = each.value.instance.subnetwork != null ? each.value.instance.subnetwork : (var.enable_network ? module.network[0].subnetwork_id : null)

  # Service account
  devvm_service_account_email = local.devvm_sa_email

  # Group for shared access (optional)
  group_team_email = var.group_team_email

  # Auto-shutdown configuration
  auto_shutdown_enabled  = var.auto_shutdown_enabled
  auto_shutdown_schedule = var.auto_shutdown_schedule
  auto_start_enabled     = var.auto_start_enabled
  auto_start_schedule    = var.auto_start_schedule
  schedule_timezone      = var.schedule_timezone

  depends_on = [module.api_enabling, module.network, module.iam]
}
