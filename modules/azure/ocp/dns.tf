# resource "azurerm_dns_zone" "zone" {
#     name                = "objectworksit.com"
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     tags                = var.tags
# }

resource "azurerm_private_dns_zone" "base" {
    name                = "${var.cluster_name}.objectworksit.com"
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
    name                = "api-int"
    zone_name           = azurerm_private_dns_zone.base.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [local.api_int_lb_ip]
    tags                = var.tags
}

resource "azurerm_private_dns_a_record" "api" {
    name                = "api"
    zone_name           = azurerm_private_dns_zone.base.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [local.api_int_lb_ip]
    tags                = var.tags
}

resource "azurerm_private_dns_a_record" "apps" {
    name                = "*.apps"
    zone_name           = azurerm_private_dns_zone.base.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [local.ingress_lb_ip]
    tags                = var.tags
}

# --------------------------
# Public DNS
# --------------------------
# # api.<cluster>.<base_domain> -> public API Public IP
# resource "azurerm_dns_a_record" "api" {
#     name                = "api.${var.cluster_name}"
#     zone_name           = azurerm_dns_zone.zone.name
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     ttl                 = 60
#     records             = [azurerm_public_ip.public_ip_api.ip_address]
#     tags                = var.tags
# }

# # *.apps.<cluster>.<base_domain> -> public Ingress Public IP
# resource "azurerm_dns_a_record" "apps_wildcard" {
#     name                = "*.apps.${var.cluster_name}"
#     zone_name           = azurerm_dns_zone.zone.name
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     ttl                 = 60
#     records             = [azurerm_public_ip.public_ip_ingress.ip_address]
#     tags                = var.tags
# }