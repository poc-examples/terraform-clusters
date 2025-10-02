module "workers" {
    source = "./modules/machines"

    for_each = local.workers_by_name

    cluster_name                = var.cluster_name
    rhcos_version               = local.rhcos_version

    machine_name                = each.key
    machine_ip                  = each.value.ip
    ssh_pubkey                  = local.ssh_pubkey

    disk_size_gb                = "200"

    location                    = data.azurerm_resource_group.cluster.location
    resource_group_name         = data.azurerm_resource_group.cluster.name

    subnet_id                   = azurerm_subnet.worker_subnet.id
    create_association          = false
    backend_address_pool_id     = null

    storage_account             = azurerm_storage_account.ign.name
    storage_account_container   = azurerm_storage_container.ign.name

    ignition_base_url           = local.worker_url

    azurerm_storage_account_primary_connection_string   = azurerm_storage_account.ign.primary_connection_string
}
