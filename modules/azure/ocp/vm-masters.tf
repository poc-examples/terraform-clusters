module "masters" {
    source = "./modules/machines"

    for_each = local.masters_by_name

    cluster_name                = var.cluster_name
    rhcos_version               = local.rhcos_version

    machine_name                = each.key
    machine_ip                  = each.value.ip
    ssh_pubkey                  = local.ssh_pubkey

    disk_size_gb                = "1024"

    location                    = data.azurerm_resource_group.cluster.location
    resource_group_name         = data.azurerm_resource_group.cluster.name

    subnet_id                   = azurerm_subnet.control_plane.id
    backend_address_pool_id     = azurerm_lb_backend_address_pool.lbp_api_internal.id

    storage_account             = azurerm_storage_account.ign.name
    storage_account_container   = azurerm_storage_container.ign.name

    ignition_base_url           = local.master_url

    azurerm_storage_account_primary_connection_string   = azurerm_storage_account.ign.primary_connection_string
}
