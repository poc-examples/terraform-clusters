locals {
    storage_account = azurerm_storage_account.ign.name
    container       = azurerm_storage_container.ign.name
    sas_token       = data.azurerm_storage_account_sas.ign_ro.sas

    ign_base        = "https://${local.storage_account}.blob.core.windows.net/${local.container}"
    
    bootstrap_url   = "${local.ign_base}/bootstrap.ign?${local.sas_token}"
    master_url      = "${local.ign_base}/master.ign?${local.sas_token}"
    worker_url      = "${local.ign_base}/worker.ign?${local.sas_token}"
    
    bootstrap_custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.bootstrap_url } }
        }
    }))

    master_custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.master_url } }
        }
    }))

    worker_custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.worker_url } }
        }
    }))
}

resource "time_static" "now" {}

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

resource "time_static" "now" {}

data "azurerm_storage_account_sas" "ign_ro" {
  connection_string = azurerm_storage_account.ign.primary_connection_string
  https_only        = true

  # start a bit in the past to avoid clock skew
  start  = timeadd(time_static.now.rfc3339, "-15m")
  expiry = timeadd(time_static.now.rfc3339, "168h") # 7 days

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  resource_types {
    service   = true
    container = true
    object    = true
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }

  # Optional but harmless to pin:
  # signed_version = "2020-08-04"
}

resource "azurerm_storage_blob" "ign_bootstrap" {
    name                   = "bootstrap.ign"
    storage_account_name   = azurerm_storage_account.ign.name
    storage_container_name = azurerm_storage_container.ign.name
    type                   = "Block"
    content_type           = "application/json"
    source                 = "/usr/src/app/terraform/bootstrap.ign"
}

resource "azurerm_storage_blob" "ign_master" {
    name                   = "master.ign"
    storage_account_name   = azurerm_storage_account.ign.name
    storage_container_name = azurerm_storage_container.ign.name
    type                   = "Block"
    content_type           = "application/json"
    source                 = "/usr/src/app/terraform/master.ign"
}

resource "azurerm_storage_blob" "ign_worker" {
    name                   = "worker.ign"
    storage_account_name   = azurerm_storage_account.ign.name
    storage_container_name = azurerm_storage_container.ign.name
    type                   = "Block"
    content_type           = "application/json"
    source                 = "/usr/src/app/terraform/worker.ign"
}
