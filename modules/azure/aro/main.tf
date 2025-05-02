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

resource "azuread_service_principal_password" "cluster" {
    service_principal_id = data.azuread_service_principal.cluster.id
}

data "azuread_service_principal" "redhatopenshift" {
  // This is the Azure Red Hat OpenShift RP service principal id
  client_id = "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
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

output "service_principal_id" {
    value = data.azuread_service_principal.cluster.object_id
}