# =============================================================================
# COMPUTED NAMES
# =============================================================================

locals {
  # Network naming
  network_name = var.network_name != null ? var.network_name : "${var.data_product}-devvm-network"
  subnet_name  = "${local.network_name}-subnet"
  router_name  = "${local.network_name}-router"
  nat_name     = "${local.network_name}-nat"

  # Service Account naming
  devvm_sa_name  = "sa-w-devvm"
  devvm_sa_email = var.enable_iam ? module.iam[0].devvm_service_account_email : null

  # Firewall naming
  firewall_iap_name      = "${local.network_name}-allow-iap"
  firewall_internal_name = "${local.network_name}-allow-internal"
}

# =============================================================================
# IAM ROLE DEFINITIONS
# =============================================================================

locals {
  # Roles for the dev VM service account
  devvm_sa_roles = [
    "roles/bigquery.user",
    "roles/logging.logWriter",
    "roles/secretmanager.viewer",
    "roles/secretmanager.secretAccessor",
  ]

  # Roles for individual developers (when no group is specified)
  developer_roles = [
    "roles/bigquery.user",
    "roles/storage.objectViewer",
    "roles/compute.viewer",
    "roles/compute.networkViewer",
    "roles/secretmanager.viewer",
    "roles/logging.viewer",
    "roles/compute.osAdminLogin",
  ]
}

# =============================================================================
# API LIST
# =============================================================================

locals {
  required_apis = [
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
