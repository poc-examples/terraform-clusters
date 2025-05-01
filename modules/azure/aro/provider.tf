terraform {
    required_providers {
        azuread = {
            source  = "hashicorp/azuread"
            version = "~>2.53"
        }
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>4.3.0"
        }
    }
}