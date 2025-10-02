locals {
    rhcos_publisher = "redhat"
    rhcos_offer     = "rh-ocp-worker"
    rhcos_sku       = "rh-ocp-worker"

    sas_token       = data.azurerm_storage_account_sas.ign_ro.sas

    ignition_url   = "${var.ignition_base_url}?${local.sas_token}"

    custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.ignition_url } }
        }
    }))
}

resource "azurerm_network_interface" "machine" {
    name                = "${var.cluster_name}-${var.machine_name}-nic"
    location            = var.location
    resource_group_name = var.resource_group_name

    ip_configuration {
        name                            = "ipconfig1"
        subnet_id                       = var.subnet_id
        private_ip_address_allocation   = "Static"
        private_ip_address              = var.machine_ip
    }
}

resource "azurerm_linux_virtual_machine" "machine" {
    name                = "${var.cluster_name}-${var.machine_name}-vm"
    location            = var.location
    resource_group_name = var.resource_group_name
    size                = "Standard_D8s_v3"
    admin_username      = "core"
    network_interface_ids = [azurerm_network_interface.machine.id]

    source_image_reference {
        publisher = local.rhcos_publisher
        offer     = local.rhcos_offer
        sku       = local.rhcos_sku
        version   = var.rhcos_version
    }

    admin_ssh_key {
        username   = "core"
        public_key = var.ssh_pubkey
    }

    plan {
        name      = local.rhcos_offer
        product   = local.rhcos_sku
        publisher = local.rhcos_publisher
    }

    custom_data = local.custom_data

    os_disk {
        name                 = "${var.cluster_name}-${var.machine_name}-disk"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = var.disk_size_gb
    }
}

resource "azurerm_network_interface_backend_address_pool_association" "lb" {
    count = var.create_association ? 1 : 0

    network_interface_id    = azurerm_network_interface.machine.id
    ip_configuration_name   = "ipconfig1"
    backend_address_pool_id = var.backend_address_pool_id
}
