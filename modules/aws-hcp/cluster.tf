data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
  description = "i dunno"
}

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

output "api_url" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.api_url
  description = "URL of the API server."
}

output "console_url" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.console_url
  description = "URL of the console."
}

output "current_version" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.current_version
  description = "The currently running version of OpenShift on the cluster."
}

output "domain" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.domain
  description = "DNS domain of cluster."
}

output "external_id" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.external_id
  description = "Unique external identifier of the cluster."
}

output "id" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.id
  description = "Unique identifier of the cluster."
}

output "ocm_properties" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.properties
  description = "Merged properties defined by OCM and the user-defined 'properties'."
}

output "state" {
  value       = rhcs_cluster_rosa_hcp.rosa_sts_cluster.state
  description = "State of the cluster."
}
