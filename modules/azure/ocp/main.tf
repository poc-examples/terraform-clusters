################
# Set Run Scope
################
locals {
    rhcos_publisher = "redhat"
    rhcos_offer     = "rh-ocp-worker"
    rhcos_sku       = "rh-ocp-worker"
    rhcos_version   = "4.17.2024100419"

    ssh_pubkey  = file("/usr/src/app/terraform/id_rsa.pub")
    metadata    = jsondecode(file("/usr/src/app/terraform/ignition/metadata.json"))

    api_int_lb_ip   = "10.0.1.5"
    ingress_lb_ip   = "10.0.2.8"

    masters = [
       { name = "master-0", ip = "10.0.1.6" },
       { name = "master-1", ip = "10.0.1.7" },
       { name = "master-2", ip = "10.0.1.8" },
    ]

    workers = [
       { name = "worker-0", ip = "10.0.2.5" },
       { name = "worker-1", ip = "10.0.2.6" },
       { name = "worker-2", ip = "10.0.2.7" },
    ]

    bootstrap = [
        { create = true, name = "bootstrap-0", ip = "10.0.0.5" }
    ]

    masters_by_name = { for m in local.masters : m.name => m }
    workers_by_name = { for w in local.workers : w.name => w }
    bootstrap_by_name = { for b in local.bootstrap : b.name => b }
}

data "azurerm_resource_group" "cluster" {
    name     = var.resource_group_name
}

resource "azurerm_marketplace_agreement" "rhcos" {
    publisher = local.rhcos_publisher
    offer     = local.rhcos_offer
    plan      = local.rhcos_sku
}

resource "azurerm_virtual_network" "network" {
    name                = "${var.cluster_name}-vnet"
    address_space       = ["10.0.0.0/22", "10.1.0.0/24"]
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
}
