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

variable "aro_version" {
    type        = string
    description = <<EOF
    ARO version
    Default "4.16.30"
    EOF
    default     = "4.16.30"
}

variable "pull_secret_path" {
    type        = string
    default     = null
    description = <<EOF
    Pull Secret for the ARO cluster
    Default null
    EOF
}

variable "pull_secret" {
    type        = string
    default     = null 
    description = <<EOF
    Pull Secret provided from config file
    EOF
}

variable "subscription_id" {
    type        = string
    description = "Azure Subscription ID (needed with the new Auth method)"
}

variable "client_secret" {
    type        = string
    description = "Azure Subscription ID (needed with the new Auth method)"
}

variable "worker_node_count" {
    type        = number
    default     = 3
    description = "Number of worker nodes."

    validation {
        condition     = var.worker_node_count >= 3
        error_message = "Invalid 'worker_node_count'. Minimum of 3."
    }
}

variable "api_int_lb_ip" {
    type        = string
    default = "10.0.0.5" # Example reserved IP
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
