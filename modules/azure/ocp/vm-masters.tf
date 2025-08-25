resource "azurerm_network_interface" "master" {
    for_each            = local.masters_by_name

    name                = "${var.cluster_name}-ni-${each.key}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name

    ip_configuration {
        name                            = "ipconfig1"
        subnet_id                       = azurerm_subnet.control_plane.id
        private_ip_address_allocation   = "Static"
        private_ip_address              = each.value.ip
    }
}

resource "azurerm_linux_virtual_machine" "master" {
    for_each            = local.masters_by_name

    name                = "${var.cluster_name}-vm-${each.key}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    size                = "Standard_D8s_v3"
    admin_username      = "core"
    network_interface_ids = [azurerm_network_interface.master[each.key].id]

    source_image_reference {
        publisher = local.rhcos_publisher
        offer     = local.rhcos_offer
        sku       = local.rhcos_sku
        version   = local.rhcos_version
    }

    admin_ssh_key {
        username   = "core"
        public_key = local.ssh_pubkey
    }

    plan {
        name      = "rh-ocp-worker"
        product   = "rh-ocp-worker"
        publisher = "redhat"
    }

    custom_data = local.master_custom_data

    os_disk {
        name                 = "${var.cluster_name}-os-${each.key}"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = "1024"
    }
}

resource "azurerm_network_interface_backend_address_pool_association" "masters_api_internal" {
    for_each                = local.masters_by_name

    network_interface_id    = azurerm_network_interface.master[each.key].id
    ip_configuration_name   = "ipconfig1"
    backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_api_internal.id
}
