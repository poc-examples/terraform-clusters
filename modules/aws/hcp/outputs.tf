output "account_id" {
  value = data.aws_caller_identity.current.account_id
  description = "The id of the current account"
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