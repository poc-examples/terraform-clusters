resource "azurerm_network_interface" "worker" {
    for_each            = local.workers_by_name

    name                = "${var.cluster_name}-ni-${each.key}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name

    ip_configuration {
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.worker_subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = each.value.ip
    }
}

resource "azurerm_linux_virtual_machine" "worker" {
    for_each            = local.workers_by_name

    name                = "${var.cluster_name}-vm-${each.key}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    size                = "Standard_D8s_v3"
    admin_username      = "core"
    network_interface_ids = [azurerm_network_interface.worker[each.key].id]

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

    custom_data = local.worker_custom_data

    os_disk {
        name                 = "${var.cluster_name}-os-${each.key}"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = "200"
    }
}

resource "azurerm_subnet_nat_gateway_association" "workers_nat" {
    subnet_id      = azurerm_subnet.worker_subnet.id
    nat_gateway_id = azurerm_nat_gateway.egress.id
}
