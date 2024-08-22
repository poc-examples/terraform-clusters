data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

resource "random_string" "random_name" {
  length           = 6
  special          = false
  upper            = false
}

locals {
  path = coalesce(var.path, "/")
  major_minor_version = substr(var.rosa_openshift_version, 0, length(regex("[0-9]+\\.[0-9]+", var.rosa_openshift_version)))
  region_azs = slice([for zone in data.aws_availability_zones.available.names : format("%s", zone)], 0, 1)
  sts_roles = {
    role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.cluster_name}-Installer-Role",
    support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.cluster_name}-Support-Role",
    instance_iam_roles = {
      master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.cluster_name}-ControlPlane-Role",
      worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.cluster_name}-Worker-Role"
    },
    operator_role_prefix = local.cluster_name,
    oidc_config_id       = rhcs_rosa_oidc_config.oidc_config.id
  }
  worker_node_replicas = coalesce(var.worker_node_replicas, 2)
  cluster_name = coalesce(var.cluster_name, "rosa-${random_string.random_name.result}")
}

resource "rhcs_cluster_rosa_classic" "rosa_sts_cluster" {
  name                 = local.cluster_name
  cloud_region         = var.region
  multi_az             = false
  aws_account_id       = data.aws_caller_identity.current.account_id
  admin_credentials    = var.admin_credentials
  availability_zones   = ["${var.region}b"]
  tags                 = var.additional_tags
  version              = var.rosa_openshift_version
  compute_machine_type = var.machine_type
  replicas             = local.worker_node_replicas
  autoscaling_enabled  = false
  sts                  = local.sts_roles
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  machine_cidr     = var.vpc_cidr_block

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z][-a-z0-9]{0,13}[a-z0-9]$", local.cluster_name))
      error_message = "ROSA cluster name must be less than 16 characters, be lower case alphanumeric, with only hyphens."
    }
  }

  depends_on = [time_sleep.wait_10_seconds]
}

resource "rhcs_cluster_wait" "wait_for_cluster_build" {
  cluster = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
  timeout = 90 # minutes
}
