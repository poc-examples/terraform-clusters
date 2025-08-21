################
# Set Run Scope
################
locals {
    rhcos_publisher = "redhat"
    rhcos_offer     = "rh-ocp-worker"
    rhcos_sku       = "rh-ocp-worker"
    rhcos_version   = "4.17.2024100419"

    ssh_pubkey = file("/usr/src/app/terraform/id_rsa.pub")

    masters = [
        # { name = "master-0", ip = "10.0.1.6" },
        # { name = "master-1", ip = "10.0.1.7" },
        # { name = "master-2", ip = "10.0.1.8" },
    ]

    workers = [
        # { name = "worker-0", ip = "10.0.2.5" },
        # { name = "worker-1", ip = "10.0.2.6" },
        # { name = "worker-2", ip = "10.0.2.7" },
    ]

    bootstrap = {
        create = true,
        name = "bootstrap-0", 
        ip = "10.0.0.5" 
    }

    masters_by_name = { for m in local.masters : m.name => m }
    workers_by_name = { for w in local.workers : w.name => w }
}

data "azurerm_resource_group" "cluster" {
    name     = var.resource_group_name
}

resource "azurerm_marketplace_agreement" "rhcos" {
    publisher = "redhat"
    offer     = "rh-ocp-worker"
    plan      = "rh-ocp-worker"
}

resource "azurerm_virtual_network" "network" {
    name                = "${var.cluster_name}-vnet"
    address_space       = ["10.0.0.0/22", "10.1.0.0/24"]
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
}


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
