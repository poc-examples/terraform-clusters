data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

resource "random_string" "random_name" {
  length           = 6
  special          = false
  upper            = false
}

resource "rhcs_cluster_rosa_hcp" "rosa_sts_cluster" {

  name                   = local.cluster_name

  cloud_region           = var.region
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_billing_account_id = data.aws_caller_identity.current.account_id

  replicas               = local.worker_node_replicas

  aws_subnet_ids         = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
  availability_zones     = [for subnet in aws_subnet.public_subnets : subnet.availability_zone]

  version                = var.rosa_openshift_version
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  sts                                 = local.sts_roles

  wait_for_create_complete            = true
  wait_for_std_compute_nodes_complete = true

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z][-a-z0-9]{0,13}[a-z0-9]$", local.cluster_name))
      error_message = "ROSA cluster name must be less than 16 characters, be lower case alphanumeric, with only hyphens."
    }
  }

  depends_on = [
    module.account_roles_hcp,
    module.oidc_config_and_provider_hcp,
    module.operator_roles_hcp
  ]

}

resource "rhcs_cluster_wait" "wait_for_cluster_build" {
  cluster = rhcs_cluster_rosa_hcp.rosa_sts_cluster.id
  timeout = 90 # minutes
}
