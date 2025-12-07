# =============================================================================
# REUSABLE TERRAFORM MODULE - GCP Development Environments
# =============================================================================
#
# This module provisions development sandbox environments on GCP including:
# - API enablement
# - VPC networking with IAP access
# - Service accounts and IAM
# - Development VMs (sandboxes)
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

  sandbox_sa_name  = local.sandbox_sa_name
  sandbox_sa_roles = local.sandbox_sa_roles
  developer_roles  = local.developer_roles

  # Individual user emails from sandbox definitions
  user_emails = [for name, config in var.sandbox.sandboxes : config.instance.owner_email]

  depends_on = [module.api_enabling]
}

# -----------------------------------------------------------------------------
# SANDBOX VMs
# -----------------------------------------------------------------------------

module "sandbox" {
  for_each = var.sandbox.sandboxes
  source   = "./modules/sandbox"

  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  data_product = var.data_product

  sandbox_name   = each.key
  sandbox_config = each.value

  # Network configuration
  network_id    = var.enable_network ? module.network[0].network_id : null
  subnetwork_id = each.value.instance.subnetwork != null ? each.value.instance.subnetwork : (var.enable_network ? module.network[0].subnetwork_id : null)

  # Service account
  sandbox_service_account_email = local.sandbox_sa_email

  # Group for shared access (optional)
  group_team_email = var.group_team_email

  depends_on = [module.api_enabling, module.network, module.iam]
}
