###################
# Internal LoadBalancer for https://api-int.<clustername>.<domain>.com
# Ports 6443 & 22623
###################
resource "azurerm_lb" "lb_api_internal" {
    name                = "${var.cluster_name}-internal"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    sku                 = "Standard"
    tags                = var.tags

    frontend_ip_configuration {
        name                          = "control-plane"
        subnet_id                     = azurerm_subnet.control_plane.id
        private_ip_address_allocation = "Static"
        private_ip_address            = local.api_int_lb_ip
    }
}

resource "azurerm_lb_backend_address_pool" "lbp_api_internal" {
    name            = "control-plane"
    loadbalancer_id = azurerm_lb.lb_api_internal.id
}

resource "azurerm_lb_probe" "probe_mcs_22623" {
    name                = "https-22623"
    loadbalancer_id     = azurerm_lb.lb_api_internal.id
    protocol            = "Https"
    # protocol            = "Tcp"
    port                = 22623
    request_path        = "/healthz"
    interval_in_seconds = 5
    number_of_probes    = 2
}

resource "azurerm_lb_probe" "probe_api_int_6443" {
    name                = "https-6443"
    loadbalancer_id     = azurerm_lb.lb_api_internal.id
    protocol            = "Https"
    # protocol            = "Tcp"
    port                = 6443
    request_path        = "/readyz"
    interval_in_seconds = 5
    number_of_probes    = 2
}

resource "azurerm_lb_rule" "rule_api_int_6443" {
    name                           = "api-int-6443"
    loadbalancer_id                = azurerm_lb.lb_api_internal.id
    protocol                       = "Tcp"
    frontend_port                  = 6443
    backend_port                   = 6443
    frontend_ip_configuration_name = "control-plane"
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_internal.id]
    probe_id                       = azurerm_lb_probe.probe_api_int_6443.id
    enable_floating_ip             = false
}

resource "azurerm_lb_rule" "rule_mcs_22623" {
    name                           = "mcs-22623"
    loadbalancer_id                = azurerm_lb.lb_api_internal.id
    protocol                       = "Tcp"
    frontend_port                  = 22623
    backend_port                   = 22623
    frontend_ip_configuration_name = "control-plane"
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_internal.id]
    probe_id                       = azurerm_lb_probe.probe_mcs_22623.id
    enable_floating_ip             = false
}
