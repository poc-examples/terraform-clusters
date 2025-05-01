locals {
  domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
}

resource "random_string" "domain" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

data "azuread_application" "example" {
  display_name = var.resource_group_name
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