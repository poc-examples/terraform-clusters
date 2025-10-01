resource "azurerm_subnet" "bootstrap" {
    name                 = "${var.cluster_name}-snet-bootstrap"
    
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.0.0/28"]

    service_endpoints    = [
        "Microsoft.Storage", 
        "Microsoft.ContainerRegistry"
    ]

    private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "bootstrap" {
    subnet_id                 = azurerm_subnet.bootstrap.id
    network_security_group_id = azurerm_network_security_group.control_plane.id
}
