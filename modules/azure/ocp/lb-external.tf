# --------------------------
# Public IPs
# --------------------------
# resource "azurerm_public_ip" "public_ip_api" {
#     name                = "${var.cluster_name}-public-ip-api"
#     location            = data.azurerm_resource_group.cluster.location
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     allocation_method   = "Static"
#     sku                 = "Standard"
#     tags                = var.tags
# }

# resource "azurerm_public_ip" "public_ip_ingress" {
#     name                = "${var.cluster_name}-public-ip-ingress"
#     location            = data.azurerm_resource_group.cluster.location
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     allocation_method   = "Static"
#     sku                 = "Standard"
#     tags                = var.tags
# }


# --------------------------
# Public API Load Balancer
# --------------------------
# Public API LB (6443)
# resource "azurerm_lb" "lb_api_public" {
#     name                = "${var.cluster_name}-lb-api-public"
#     location            = data.azurerm_resource_group.cluster.location
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     sku                 = "Standard"
#     tags                = var.tags

#     frontend_ip_configuration {
#         name                 = "fe"
#         public_ip_address_id = azurerm_public_ip.public_ip_api.id
#     }
# }

# resource "azurerm_lb_backend_address_pool" "lbp_api_public" {
#     name            = "be"
#     loadbalancer_id = azurerm_lb.lb_api_public.id
# }

# resource "azurerm_lb_rule" "rule_api_6443" {
#     name                           = "api-6443"
#     loadbalancer_id                = azurerm_lb.lb_api_public.id
#     protocol                       = "Tcp"
#     frontend_port                  = 6443
#     backend_port                   = 6443
#     frontend_ip_configuration_name = "fe"
#     backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_public.id]
#     #   probe_id                       = azurerm_lb_probe.probe_api_6443.id
# }

# resource "azurerm_lb_probe" "probe_api_6443" {
#   name                = "tcp-6443"
#   loadbalancer_id     = azurerm_lb.lb_api_public.id
#   protocol            = "Tcp"
#   port                = 6443
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }


# --------------------------
# Public Ingress Load Balancer
# --------------------------
# Public Ingress LB (80/443)
# resource "azurerm_lb" "lb_ingress_public" {
#     name                = "${var.cluster_name}-lb-ingress-public"
#     location            = data.azurerm_resource_group.cluster.location
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     sku                 = "Standard"
#     tags                = var.tags

#     frontend_ip_configuration {
#         name                 = "ingress-frontend"
#         public_ip_address_id = azurerm_public_ip.public_ip_ingress.id
#     }
# }

# resource "azurerm_lb_backend_address_pool" "lbp_ingress_public" {
#     name            = "ingress-backend"
#     loadbalancer_id = azurerm_lb.lb_ingress_public.id
# }

# resource "azurerm_lb_probe" "probe_http_80" {
#     name                = "tcp-80"
#     loadbalancer_id     = azurerm_lb.lb_ingress_public.id
#     protocol            = "Tcp"
#     port                = 80
#     interval_in_seconds = 5
#     number_of_probes    = 2
# }

# resource "azurerm_lb_probe" "probe_https_443" {
#     name                = "tcp-443"
#     loadbalancer_id     = azurerm_lb.lb_ingress_public.id
#     protocol            = "Tcp"
#     port                = 443
#     interval_in_seconds = 5
#     number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "rule_ingress_80" {
#     name                           = "ingress-80"
#     loadbalancer_id                = azurerm_lb.lb_ingress_public.id
#     protocol                       = "Tcp"
#     frontend_port                  = 80
#     backend_port                   = 80
#     frontend_ip_configuration_name = "ingress-frontend"
#     backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_ingress_public.id]
#     probe_id                       = azurerm_lb_probe.probe_http_80.id
#     enable_floating_ip             = false
# }

# resource "azurerm_lb_rule" "rule_ingress_443" {
#     name                           = "ingress-443"
#     loadbalancer_id                = azurerm_lb.lb_ingress_public.id
#     protocol                       = "Tcp"
#     frontend_port                  = 443
#     backend_port                   = 443
#     frontend_ip_configuration_name = "ingress-frontend"
#     backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_ingress_public.id]
#     probe_id                       = azurerm_lb_probe.probe_https_443.id
#     enable_floating_ip             = false
# }

