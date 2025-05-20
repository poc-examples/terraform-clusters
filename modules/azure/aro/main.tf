locals {
    domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
    pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(var.pull_secret_path) : null
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
    display_name = "api://${var.resource_group_name}"
}

data "azuread_service_principal" "cluster" {
    client_id = data.azuread_application.cluster.client_id
}

data "azuread_service_principal" "redhatopenshift" {
    // This is the Azure Red Hat OpenShift RP service principal id
    client_id = "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
}

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

resource "azurerm_subnet" "main_subnet" {
    name                 = "main-subnet"
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.0.0/23"]
    service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]

    private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "worker_subnet" {
    name                 = "worker-subnet"
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.2.0/23"]
    service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

resource "azurerm_redhat_openshift_cluster" "cluster" {
    name                = var.cluster_name
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name

    cluster_profile {
        domain          = local.domain
        pull_secret     = var.pull_secret
        version         = "4.16.30"
    }

    network_profile {
        pod_cidr     = "10.128.0.0/14"
        service_cidr = "172.30.0.0/16"
    }

    main_profile {
        vm_size   = "Standard_D8s_v3"
        subnet_id = azurerm_subnet.main_subnet.id
    }

    api_server_profile {
        visibility = "Public"
    }

    ingress_profile {
        visibility = "Public"
    }

    worker_profile {
        vm_size      = "Standard_D4s_v3"
        disk_size_gb = 128
        node_count   = var.worker_node_count
        subnet_id    = azurerm_subnet.worker_subnet.id
    }

    service_principal {
        client_id     = data.azuread_application.cluster.client_id
        client_secret = var.client_secret
    }

    depends_on = [
        azurerm_role_assignment.role_network1,
        azurerm_role_assignment.role_network2,
    ]
}

output "api_url" {
    value = azurerm_redhat_openshift_cluster.cluster.api_server_profile[0].url
}

output "console_url" {
    value = azurerm_redhat_openshift_cluster.cluster.console_url
}

output "domain" {
    value = "${local.domain}.${var.location}.aroapp.io"
}
