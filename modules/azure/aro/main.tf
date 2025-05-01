locals {
  domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
}

resource "random_string" "domain" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

data "azurerm_client_config" "example" {}

data "azuread_client_config" "example" {}

data "azuread_application" "example" {
  display_name = var.cluster_name
}

data "azuread_service_principal" "example" {
  client_id = data.azuread_application.client_id
}

data "azuread_service_principal_password" "example" {
  service_principal_id = data.azuread_service_principal.example.object_id
}

data "azuread_service_principal" "redhatopenshift" {
  // This is the Azure Red Hat OpenShift RP service principal id, do NOT delete it
  client_id = "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
}

output "console_url" {
  value = "stuff
}

output "domain" {
  value = local.domain
}