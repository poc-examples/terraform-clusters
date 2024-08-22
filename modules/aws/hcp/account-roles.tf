data "rhcs_versions" "all" {
  search = <<-EOT
    enabled='t' and 
    rosa_enabled='t' and 
    hosted_control_plane_enabled='t' and 
    channel_group='stable'
  EOT
  order = "id"
}

module "account_roles_hcp" {
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/account-iam-resources"
  version = "1.6.2"

  account_role_prefix = var.cluster_name
  tags                = var.additional_tags
}
