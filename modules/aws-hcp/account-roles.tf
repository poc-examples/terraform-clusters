# Data source to retrieve all RHCS versions that meet the following criteria:
# - The version is enabled (`enabled='t'`)
# - The version is enabled for ROSA (`rosa_enabled='t'`)
# - The version supports Hosted Control Plane (HCP) architecture (`hosted_control_plane_enabled='t'`)
# - The version belongs to the 'stable' channel group (`channel_group='stable'`)
# The results are ordered by the version ID.

data "rhcs_versions" "all" {
  search = <<-EOT
    enabled='t' and 
    rosa_enabled='t' and 
    hosted_control_plane_enabled='t' and 
    channel_group='stable'
  EOT
  order = "id"
}

# This module creates the necessary IAM roles for the ROSA Hosted Control Plane (HCP) deployment.
# 
# - `account_role_prefix`: Prefix used for naming the IAM roles associated with the cluster. 
#   This is typically set to the cluster name to ensure unique role names.
# - `tags`: Additional tags to apply to the IAM roles for resource identification and management.
# 
# The module source is `terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources`, 
# version `1.6.2`, which is specifically designed for setting up IAM resources 
# required by the ROSA HCP.

module "account_roles_hcp" {
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources"
  version = "1.6.2"

  account_role_prefix = var.cluster_name
  tags                = var.additional_tags
}
