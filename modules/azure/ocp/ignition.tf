# https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
locals {
    storage_account = azurerm_storage_account.ign.name
    container       = azurerm_storage_container.ign.name

    ign_base        = "https://${local.storage_account}.blob.core.windows.net/${local.container}"
    
    bootstrap_url   = "${local.ign_base}/bootstrap.ign"
    master_url      = "${local.ign_base}/master.ign"
    worker_url      = "${local.ign_base}/worker.ign"
}

resource "azurerm_storage_account" "ign" {
    name                     = substr(lower(replace("${var.cluster_name}ignservicecbe", "/[^a-z0-9]/", "")), 0, 24)
    resource_group_name      = data.azurerm_resource_group.cluster.name
    location                 = data.azurerm_resource_group.cluster.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "ign" {
    name                  = "ignition"
    storage_account_name  = azurerm_storage_account.ign.name
    container_access_type = "private"
}

resource "terraform_data" "ign_bootstrap" {
    triggers_replace = [filesha256("/usr/src/app/terraform/ignition/bootstrap.ign")]
    input            = filesha256("/usr/src/app/terraform/ignition/bootstrap.ign")
}

resource "azurerm_storage_blob" "ign_bootstrap" {
    name                   = "bootstrap.ign"
    storage_account_name   = azurerm_storage_account.ign.name
    storage_container_name = azurerm_storage_container.ign.name
    type                   = "Block"
    content_type           = "application/json"
    source                 = "/usr/src/app/terraform/ignition/bootstrap.ign"

    lifecycle {
        replace_triggered_by = [ terraform_data.ign_bootstrap ]
    }
}

resource "terraform_data" "ign_master" {
    triggers_replace = [filesha256("/usr/src/app/terraform/ignition/master.ign")]
    input            = filesha256("/usr/src/app/terraform/ignition/master.ign")
}

resource "azurerm_storage_blob" "ign_master" {
    name                   = "master.ign"
    storage_account_name   = azurerm_storage_account.ign.name
    storage_container_name = azurerm_storage_container.ign.name
    type                   = "Block"
    content_type           = "application/json"
    source                 = "/usr/src/app/terraform/ignition/master.ign"

    lifecycle {
        replace_triggered_by = [ terraform_data.ign_master ]
    }
}

resource "terraform_data" "ign_worker" {
    triggers_replace = [filesha256("/usr/src/app/terraform/ignition/worker.ign")]
    input            = filesha256("/usr/src/app/terraform/ignition/worker.ign")
}

resource "azurerm_storage_blob" "ign_worker" {
    name                   = "worker.ign"
    storage_account_name   = azurerm_storage_account.ign.name
    storage_container_name = azurerm_storage_container.ign.name
    type                   = "Block"
    content_type           = "application/json"
    source                 = "/usr/src/app/terraform/ignition/worker.ign"

    lifecycle {
        replace_triggered_by = [ terraform_data.ign_worker ]
    }
}
