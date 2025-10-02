variable "azurerm_storage_account_primary_connection_string" {
  type        = string
  description = "Connection String for Azure Storage Account"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Cluster"
}


variable "machine_name" {
  type        = string
  description = "Name of the Machine"
}

variable "machine_ip" {
  type        = string
  description = "Name of the Machine"
}

variable "location" {
  type        = string
  description = "Azure Location"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Machine"
}

variable "subnet_id" {
  type        = string
  description = "Id of the subnet for bootstrap Machine"
}

variable "rhcos_version" {
  type        = string
  description = "Version of the OCP Cluster"
}

variable "ssh_pubkey" {
  type        = string
  description = "SSH Pubkey for accessing OCP Cluster"
}

variable "backend_address_pool_id" {
  type        = string
  description = "Control Plane Backend Address Pool Id"
}

variable "storage_account" {
  type        = string
  description = "Storage Account Name for Ignition"   
}

variable "storage_account_container" {
  type        = string
  description = "Storage Container Name for Ignition"   
}

variable "ignition_base_url" {
  type        = string
  description = "Base Ignition url for the machine"   
}

variable "disk_size_gb" {
  type        = string
  description = "The base storage size for machine"   
}

variable "create_association" {
  type    = bool
  default = true
  description = "Attach to LoadBalancer"   
}
