resource "azurerm_subnet" "worker_subnet" {
    name                 = "${var.cluster_name}-snet-workers"

    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.2.0/23"]

    service_endpoints    = [
        "Microsoft.Storage", 
        "Microsoft.ContainerRegistry"
    ]
}

resource "azurerm_network_security_group" "worker_subnet" {
    name                = "${var.cluster_name}-nsg-workers"

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

resource "azurerm_subnet_network_security_group_association" "worker_subnet" {
    subnet_id                 = azurerm_subnet.worker_subnet.id
    network_security_group_id = azurerm_network_security_group.worker_subnet.id
}

resource "azurerm_subnet_nat_gateway_association" "workers_nat" {
    subnet_id      = azurerm_subnet.worker_subnet.id
    nat_gateway_id = azurerm_nat_gateway.nat_egress.id
}
