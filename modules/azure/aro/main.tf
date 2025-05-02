locals {
    domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
}

resource "random_string" "domain" {
    length  = 8
    special = false
    upper   = false
    numeric = false
}

data "azurerm_client_config" "cluster" {}

data "azuread_client_config" "cluster" {}

data "azuread_application" "cluster" {
    display_name = "api://openenv-xjfl9"
}

data "azuread_service_principal" "cluster" {
    client_id = data.azuread_application.cluster.client_id
}

data "azuread_service_principal" "redhatopenshift" {
    // This is the Azure Red Hat OpenShift RP service principal id
    client_id = "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
}



// START
data "azurerm_resource_group" "cluster" {
    name     = var.resource_group_name
}

resource "azurerm_virtual_network" "network" {
    name                = "${var.cluster_name}-vnet"
    address_space       = ["10.0.0.0/22"]
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
}

resource "azurerm_role_assignment" "role_network1" {
    scope                = azurerm_virtual_network.network.id
    role_definition_name = "Network Contributor"
    principal_id         = data.azuread_service_principal.cluster.object_id
}

resource "azurerm_role_assignment" "role_network2" {
    scope                = azurerm_virtual_network.network.id
    role_definition_name = "Network Contributor"
    principal_id         = data.azuread_service_principal.redhatopenshift.object_id
}

output "api_url" {
    value = "stuff"
}

output "console_url" {
    value = "stuff"
}

output "domain" {
    value = local.domain
}
