
output "api_url" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.api_url
  description = "URL of the API server."
}

output "ccs_enabled" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.ccs_enabled
  description = "Enables customer cloud subscription (Immutable with ROSA)"
}

output "console_url" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.console_url
  description = "URL of the console."
}

output "current_version" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.current_version
  description = "The currently running version of OpenShift on the cluster."
}

output "domain" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.domain
  description = "DNS domain of cluster."
}

output "external_id" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.external_id
  description = "Unique external identifier of the cluster."
}

output "id" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
  description = "Unique identifier of the cluster."
}

output "infra_id" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.infra_id
  description = "The ROSA cluster infrastructure ID."
}

output "ocm_properties" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.properties
  description = "Merged properties defined by OCM and the user-defined 'properties'."
}

output "state" {
  value       = rhcs_cluster_rosa_classic.rosa_sts_cluster.state
  description = "State of the cluster."
}