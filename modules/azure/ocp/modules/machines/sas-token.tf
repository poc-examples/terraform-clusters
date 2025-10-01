resource "time_static" "now" {}

data "azurerm_storage_account_sas" "ign_ro" {
  connection_string = var.azurerm_storage_account_primary_connection_string
  https_only        = true

  start  = timeadd(time_static.now.rfc3339, "-15m")
  expiry = timeadd(time_static.now.rfc3339, "168h") 

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

}
