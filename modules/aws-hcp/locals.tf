locals {

    account_role_arns = module.account_roles_hcp.account_roles_arn

    major_minor_version = substr(var.rosa_openshift_version, 0, length(regex("[0-9]+\\.[0-9]+", var.rosa_openshift_version)))
    region_azs = slice([for zone in data.aws_availability_zones.available.names : format("%s", zone)], 0, 1)

    oidc = module.oidc_config_and_provider_hcp

    sts_roles = {
        
        role_arn         = local.account_role_arns.HCP-ROSA-Installer,
        support_role_arn = local.account_role_arns.HCP-ROSA-Support,
        
        instance_iam_roles = {
            worker_role_arn = local.account_role_arns.HCP-ROSA-Worker
        },

        operator_role_prefix = local.cluster_name,
        oidc_config_id       = local.oidc.oidc_config_id
        oidc_endpoint_url    = local.oidc.oidc_endpoint_url
    }

    worker_node_replicas = coalesce(var.worker_node_replicas, 2)
    cluster_name = coalesce(var.cluster_name, "rosa-${random_string.random_name.result}")

}

