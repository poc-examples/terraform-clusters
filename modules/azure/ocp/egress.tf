resource "azurerm_public_ip" "nat_egress" {
    name                = "${var.cluster_name}-nat-pip"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

resource "azurerm_nat_gateway" "nat_egress" {
    name                = "${var.cluster_name}-nat"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    sku_name            = "Standard"
    idle_timeout_in_minutes = 4
    tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_egress" {
    nat_gateway_id       = azurerm_nat_gateway.nat_egress.id
    public_ip_address_id = azurerm_public_ip.nat_egress.id
}

resource "azurerm_subnet_nat_gateway_association" "nat-egress" {
    subnet_id      = azurerm_subnet.bootstrap.id
    nat_gateway_id = azurerm_nat_gateway.nat_egress.id
}

resource "azurerm_subnet_nat_gateway_association" "control-nat-egress" {
    subnet_id      = azurerm_subnet.control_plane.id
    nat_gateway_id = azurerm_nat_gateway.nat_egress.id
}
