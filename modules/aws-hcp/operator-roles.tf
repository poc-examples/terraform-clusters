module "operator_roles_hcp" {

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/operator-roles"
  version = "1.6.2"

  oidc_endpoint_url    = module.oidc_config_and_provider_hcp.oidc_endpoint_url
  operator_role_prefix = var.cluster_name
  tags                 = var.additional_tags
}

output "operator_control_arns" {
  value       = module.operator_roles_hcp.operator_roles_arn
  description = "operator_roles_arn"
}

output "operator_role_prefix" {
  value       = module.operator_roles_hcp.operator_role_prefix
  description = "operator_role_prefix"
}