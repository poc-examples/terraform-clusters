data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

module "create_account_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.16"

  create_account_roles  = true

  account_role_prefix    = var.cluster_name
  ocm_environment        = var.ocm_environment
  rosa_openshift_version = var.rosa_openshift_version
  account_role_policies  = data.rhcs_policies.all_policies.account_role_policies
  operator_role_policies = data.rhcs_policies.all_policies.operator_role_policies
  all_versions           = data.rhcs_versions.all
  path                   = var.path
  tags                   = var.additional_tags
}

resource "time_sleep" "wait_10_seconds" {
  depends_on = [module.create_account_roles]

  create_duration = "10s"
}
