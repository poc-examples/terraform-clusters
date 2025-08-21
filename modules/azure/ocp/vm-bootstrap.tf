resource "azurerm_network_interface" "bootstrap" {
    name                = "${var.cluster_name}-nic-${local.bootstrap.name}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name

    ip_configuration {
        name                            = "ipconfig1"
        subnet_id                       = azurerm_subnet.bootstrap.id
        private_ip_address_allocation   = "Static"
        private_ip_address              = local.bootstrap.ip
    }
}

resource "azurerm_linux_virtual_machine" "bootstrap" {
    name                = "${var.cluster_name}-vm-${local.bootstrap.name}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    size                = "Standard_D8s_v3"
    admin_username      = "core"
    network_interface_ids = [azurerm_network_interface.bootstrap.id]

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

    custom_data = local.bootstrap_custom_data

    os_disk {
        name                 = "${var.cluster_name}-os-${local.bootstrap.name}"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = "200"
    }
}

resource "azurerm_network_interface_backend_address_pool_association" "bootstrap_api_internal" {
    network_interface_id    = azurerm_network_interface.bootstrap.id
    ip_configuration_name   = "ipconfig1"
    backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_api_internal.id
}