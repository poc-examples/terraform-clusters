resource "azurerm_subnet" "control_plane" {
    name                 = "${var.cluster_name}-snet-control-plane"

    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.1.0/27"]

    service_endpoints    = [
        "Microsoft.Storage", 
        "Microsoft.ContainerRegistry"
    ]

    private_link_service_network_policies_enabled = false
}

resource "azurerm_network_security_group" "control_plane" {
    name                = "${var.cluster_name}-nsg-control-plane"

    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags

    dynamic "security_rule" {
        for_each = [
            {
                name                   = "allow-all"
                priority               = 120
                direction              = "Inbound"
                access                 = "Allow"
                protocol               = "*"
                source_port_range      = "*"
                destination_port_range = "*"
                source_address_prefix  = "*"
                destination_address_prefix = "*"
            }
        ]

        content {
            name                       = security_rule.value.name
            priority                   = security_rule.value.priority
            direction                  = security_rule.value.direction
            access                     = security_rule.value.access
            protocol                   = security_rule.value.protocol
            source_port_range          = security_rule.value.source_port_range
            destination_port_range     = security_rule.value.destination_port_range
            source_address_prefix      = security_rule.value.source_address_prefix
            destination_address_prefix = security_rule.value.destination_address_prefix
        }
        
    }
}

resource "azurerm_subnet_network_security_group_association" "control_plane" {
    subnet_id                 = azurerm_subnet.control_plane.id
    network_security_group_id = azurerm_network_security_group.control_plane.id
}
