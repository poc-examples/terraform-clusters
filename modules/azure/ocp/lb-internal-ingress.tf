###################
# Internal LoadBalancer for https://*.apps.<clustername>.<domain>.com
# Ports 443 & 80
###################
# resource "azurerm_lb" "lb_ingress_internal" {
#     name                = "${var.cluster_name}-ingress-internal"
#     location            = data.azurerm_resource_group.cluster.location
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     sku                 = "Standard"
#     tags                = var.tags

#     frontend_ip_configuration {
#         name                          = "ingress"
#         subnet_id                     = azurerm_subnet.worker_subnet.id
#         private_ip_address_allocation = "Static"
#         private_ip_address            = local.ingress_lb_ip
#     }
# }

# resource "azurerm_lb_backend_address_pool" "lb_ingress_internal" {
#     name            = "ingress"
#     loadbalancer_id = azurerm_lb.lb_ingress_internal.id
# }

# resource "azurerm_lb_probe" "probe_ingress_80" {
#     name                = "http-80"
#     loadbalancer_id     = azurerm_lb.lb_ingress_internal.id
#     protocol            = "Http"
#     # protocol            = "Tcp"
#     port                = 80
#     request_path        = "/healthz"
#     interval_in_seconds = 5
#     number_of_probes    = 2
# }

# resource "azurerm_lb_probe" "probe_ingress_443" {
#     name                = "https-443"
#     loadbalancer_id     = azurerm_lb.lb_ingress_internal.id
#     protocol            = "Https"
#     # protocol            = "Tcp"
#     port                = 443
#     request_path        = "/healthz"
#     interval_in_seconds = 5
#     number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "rule_ingress_443" {
#     name                           = "ingress-443"
#     loadbalancer_id                = azurerm_lb.lb_ingress_internal.id
#     protocol                       = "Tcp"
#     frontend_port                  = 443
#     backend_port                   = 443
#     frontend_ip_configuration_name = "ingress"
#     backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_ingress_internal.id]
#     probe_id                       = azurerm_lb_probe.probe_ingress_443.id
#     enable_floating_ip             = false
# }

# resource "azurerm_lb_rule" "rule_ingress_80" {
#     name                           = "ingress-80"
#     loadbalancer_id                = azurerm_lb.lb_ingress_internal.id
#     protocol                       = "Tcp"
#     frontend_port                  = 80
#     backend_port                   = 80
#     frontend_ip_configuration_name = "ingress"
#     backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_ingress_internal.id]
#     probe_id                       = azurerm_lb_probe.probe_ingress_80.id
#     enable_floating_ip             = false
# }

resource "azurerm_network_security_group" "loadbalancer_nsg" {
    name                = "${local.metadata.infraID}-nsg"

    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags

    lifecycle {
        ignore_changes = [
            tags,
            security_rule,
        ]
    }

}