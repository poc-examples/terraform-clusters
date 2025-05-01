locals {
  domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
}

resource "random_string" "domain" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

data "azuread_service_principal" "redhatopenshift" {
  // This is the Azure Red Hat OpenShift RP service principal id, do NOT delete it
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