resource "azurerm_network_interface" "nettest" {
    name                = "${var.cluster_name}-ni-nettest"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name

    ip_configuration {
        name                            = "ipconfig1"
        subnet_id                       = azurerm_subnet.control_plane.id
        private_ip_address_allocation   = "Static"
        private_ip_address              = "10.0.1.9"
    }

    tags = var.tags
}

resource "azurerm_linux_virtual_machine" "nettest" {
  name                = "${var.cluster_name}-vm-nettest"
  location            = data.azurerm_resource_group.cluster.location
  resource_group_name = data.azurerm_resource_group.cluster.name
  size                = "Standard_D8s_v3"
  admin_username      = "ubuntu"
  network_interface_ids = [azurerm_network_interface.nettest.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "ubuntu"
    public_key = local.ssh_pubkey
  }

  # Handy tools for quick network tests
  custom_data = base64encode(<<EOF
#cloud-config
package_update: true
packages:
  - jq
  - curl
  - dnsutils
  - tcpdump
  - traceroute
  - netcat-openbsd
runcmd:
  - [ bash, -lc, "echo 'nettest ready' | systemd-cat -t nettest" ]
EOF
  )

  os_disk {
    name                 = "${var.cluster_name}-os-nettest"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  tags = var.tags
}
