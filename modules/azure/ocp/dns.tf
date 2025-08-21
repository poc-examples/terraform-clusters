resource "azurerm_dns_zone" "zone" {
    name                = "objectworksit.com"
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags
}

resource "azurerm_private_dns_zone" "base" {
    name                = "objectworksit.com"
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "base_link" {
    name                  = "${var.cluster_name}-private-dns-link"
    resource_group_name   = data.azurerm_resource_group.cluster.name
    private_dns_zone_name = azurerm_private_dns_zone.base.name
    virtual_network_id    = azurerm_virtual_network.network.id
    registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "api_int" {
    name                = "api-int.${var.cluster_name}"
    zone_name           = azurerm_private_dns_zone.base.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [var.api_int_lb_ip]
    tags                = var.tags
}
