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
