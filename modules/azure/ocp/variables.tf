variable "cluster_name" {
    type        = string
    default     = "my-aro-cluster"
    description = "ARO cluster name"
}

variable "resource_group_name" {
    type        = string
    default     = null
    description = "ARO resource group name"
}

variable "location" {
    type        = string
    default     = "eastus"
    description = "Azure region"
}

variable "tags" {
    type = map(string)
    default = {
        environment = "development"
        owner       = "your@email.address"
    }
}

# variable "vnet_cidr" {
#   description = "CIDR for the VNet."
#   type        = string
# }

# variable "subnet_cidrs" {
#   description = "Subnets for control-plane, workers, and (optionally) bootstrap."
#   type = object({
#     control_plane = string
#     workers       = string
#     bootstrap     = optional(string, null)
#   })
# }

# variable "api_int_lb_ip" {
#   description = "Static private IP for the internal API/MCS LB (must be inside control-plane subnet)."
#   type        = string
# }

# variable "create_dns_zone" {
#   description = "Create Azure DNS zone and records for API/Ingress."
#   type        = bool
#   default     = false
# }

# variable "base_domain" {
#   description = "Base DNS zone (e.g., example.com). Used if create_dns_zone=true."
#   type        = string
#   default     = null
# }

# variable "cluster_name" {
#   description = "Cluster name (e.g., mycluster)."
#   type        = string
# }

# variable "dns_resource_group_name" {
#   description = "Resource group to place the DNS zone in (defaults to this module's RG)."
#   type        = string
#   default     = null
# }

# variable "lockdown_nsg" {
#   description = "If true, NSGs restrict inbound to essential OCP/LB traffic; otherwise permissive inside VNet."
#   type        = bool
#   default     = true
# }
