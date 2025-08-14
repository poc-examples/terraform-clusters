# locals {
#     domain = var.domain != null && var.domain != "" ? var.domain : random_string.domain.result
#     pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(var.pull_secret_path) : null
# }

# resource "random_string" "domain" {
#     length  = 8
#     special = false
#     upper   = false
#     numeric = false
# }

# data "azurerm_client_config" "cluster" {}

# data "azuread_client_config" "cluster" {}

# data "azuread_application" "cluster" {
#     display_name = "api://${var.resource_group_name}"
# }

# data "azuread_service_principal" "cluster" {
#     client_id = data.azuread_application.cluster.client_id
# }

# data "azuread_service_principal" "redhatopenshift" {
#     // This is the Azure Red Hat OpenShift RP service principal id
#     client_id = "f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"
# }

# provider "azurerm" {
#   features {}
# }

data "azurerm_resource_group" "cluster" {
    name     = var.resource_group_name
}

# --------------------------
# Networking: VNet + Subnets
# --------------------------
resource "azurerm_virtual_network" "network" {
    name                = "${var.cluster_name}-vnet"
    address_space       = ["10.0.0.0/22"]
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
}

resource "azurerm_subnet" "control_plane" {
    name                 = "${var.cluster_name}-snet-control"
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.0.0/23"]
    service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]

    private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "worker_subnet" {
    name                 = "${var.cluster_name}-snet-workers"
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.0.2.0/23"]
    service_endpoints    = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

# --------------------------
# NSGs Control Plane Lockdown
# --------------------------
resource "azurerm_network_security_group" "control_plane" {
    name                = "${var.cluster_name}-nsg-control"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags

    dynamic "security_rule" {
        for_each = [
            # Allow intra-VNet
            {
                name                       = "allow-vnet-intra"
                priority                   = 100
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "*"
                source_port_range          = "*"
                destination_port_range     = "*"
                source_address_prefix      = "VirtualNetwork"
                destination_address_prefix = "VirtualNetwork"
            },
            # API 6443 (internal/external LBs)
            {
                name                   = "allow-api-6443"
                priority               = 110
                direction              = "Inbound"
                access                 = "Allow"
                protocol               = "Tcp"
                source_port_range      = "*"
                destination_port_range = "6443"
                source_address_prefix  = "*"
                destination_address_prefix = "*"
            },
            # MCS 22623 (internal LB / nodes)
            {
                name                   = "allow-mcs-22623"
                priority               = 120
                direction              = "Inbound"
                access                 = "Allow"
                protocol               = "Tcp"
                source_port_range      = "*"
                destination_port_range = "22623"
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

# --------------------------
# NSGs Worker Subnet Lockdown
# --------------------------
resource "azurerm_network_security_group" "worker_subnet" {
    name                = "${var.cluster_name}-nsg-workers"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags

    dynamic "security_rule" {
        for_each = [
            # Allow intra-VNet
            {
                name                       = "allow-vnet-intra"
                priority                   = 100
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "*"
                source_port_range          = "*"
                destination_port_range     = "*"
                source_address_prefix      = "VirtualNetwork"
                destination_address_prefix = "VirtualNetwork"
            },
            # Ingress 80/443 from Internet (via LB)
            {
                name                   = "allow-ingress-80"
                priority               = 110
                direction              = "Inbound"
                access                 = "Allow"
                protocol               = "Tcp"
                source_port_range      = "*"
                destination_port_range = "80"
                source_address_prefix  = "*"
                destination_address_prefix = "*"
            },
            {
                name                   = "allow-ingress-443"
                priority               = 120
                direction              = "Inbound"
                access                 = "Allow"
                protocol               = "Tcp"
                source_port_range      = "*"
                destination_port_range = "443"
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

# --------------------------
# Public IPs
# --------------------------
resource "azurerm_public_ip" "public_ip_api" {
    name                = "${var.cluster_name}-public-ip-api"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

resource "azurerm_public_ip" "public_ip_ingress" {
    name                = "${var.cluster_name}-public-ip-ingress"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

# --------------------------
# Load Balancer
# --------------------------
# Public API LB (6443)
resource "azurerm_lb" "lb_api_public" {
    name                = "${var.cluster_name}-lb-api-public"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    sku                 = "Standard"
    tags                = var.tags

    frontend_ip_configuration {
        name                 = "fe"
        public_ip_address_id = azurerm_public_ip.public_ip_api.id
    }
}

resource "azurerm_lb_backend_address_pool" "lbp_api_public" {
  name            = "be"
  loadbalancer_id = azurerm_lb.lb_api_public.id
}

resource "azurerm_lb_rule" "rule_api_6443" {
  name                           = "api-6443"
  loadbalancer_id                = azurerm_lb.lb_api_public.id
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_public.id]
#   probe_id                       = azurerm_lb_probe.probe_api_6443.id
}

# resource "azurerm_lb_probe" "probe_api_6443" {
#   name                = "tcp-6443"
#   loadbalancer_id     = azurerm_lb.lb_api_public.id
#   protocol            = "Tcp"
#   port                = 6443
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }


# --------------------------
# Load Balancer
# --------------------------
# Public Ingress LB (80/443)
resource "azurerm_lb" "lb_ingress_public" {
    name                = "${var.cluster_name}-lb-ingress-public"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    sku                 = "Standard"
    tags                = var.tags

    frontend_ip_configuration {
        name                 = "fe"
        public_ip_address_id = azurerm_public_ip.public_ip_ingress.id
    }
}

resource "azurerm_lb_backend_address_pool" "lbp_ingress_public" {
  name            = "be"
  loadbalancer_id = azurerm_lb.lb_ingress_public.id
}

resource "azurerm_lb_rule" "rule_ingress_80" {
  name                           = "ingress-80"
  loadbalancer_id                = azurerm_lb.lb_ingress_public.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_ingress_public.id]
#   probe_id                       = azurerm_lb_probe.probe_http_80.id
}

resource "azurerm_lb_rule" "rule_ingress_443" {
  name                           = "ingress-443"
  loadbalancer_id                = azurerm_lb.lb_ingress_public.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_ingress_public.id]
#   probe_id                       = azurerm_lb_probe.probe_https_443.id
}

# resource "azurerm_lb_probe" "probe_http_80" {
#   name                = "tcp-80"
#   loadbalancer_id     = azurerm_lb.lb_ingress_public.id
#   protocol            = "Tcp"
#   port                = 80
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_probe" "probe_https_443" {
#   name                = "tcp-443"
#   loadbalancer_id     = azurerm_lb.lb_ingress_public.id
#   protocol            = "Tcp"
#   port                = 443
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }















# # Internal API/MCS LB (6443 + 22623)
# resource "azurerm_lb" "lb_api_internal" {
#   name                = "${var.cluster_name}-lb-api-internal"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "Standard"
#   tags                = var.tags

#   frontend_ip_configuration {
#     name                          = "fe"
#     subnet_id                     = azurerm_subnet.control_plane.id
#     private_ip_address_allocation = "Static"
#     private_ip_address            = var.api_int_lb_ip
#   }
# }

# resource "azurerm_lb_backend_address_pool" "lbp_api_internal" {
#   name            = "be"
#   loadbalancer_id = azurerm_lb.lb_api_internal.id
# }

# resource "azurerm_lb_probe" "probe_api_int_6443" {
#   name                = "tcp-6443"
#   loadbalancer_id     = azurerm_lb.lb_api_internal.id
#   protocol            = "Tcp"
#   port                = 6443
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_probe" "probe_mcs_22623" {
#   name                = "tcp-22623"
#   loadbalancer_id     = azurerm_lb.lb_api_internal.id
#   protocol            = "Tcp"
#   port                = 22623
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "rule_api_int_6443" {
#   name                           = "api-int-6443"
#   loadbalancer_id                = azurerm_lb.lb_api_internal.id
#   protocol                       = "Tcp"
#   frontend_port                  = 6443
#   backend_port                   = 6443
#   frontend_ip_configuration_name = "fe"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_internal.id]
#   probe_id                       = azurerm_lb_probe.probe_api_int_6443.id
# }

# resource "azurerm_lb_rule" "rule_mcs_22623" {
#   name                           = "mcs-22623"
#   loadbalancer_id                = azurerm_lb.lb_api_internal.id
#   protocol                       = "Tcp"
#   frontend_port                  = 22623
#   backend_port                   = 22623
#   frontend_ip_configuration_name = "fe"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_internal.id]
#   probe_id                       = azurerm_lb_probe.probe_mcs_22623.id
# }

# # --------------------------
# # (Optional) DNS
# # --------------------------
# locals {
#   dns_rg_name = coalesce(var.dns_resource_group_name, azurerm_resource_group.rg.name)
# }

# resource "azurerm_resource_group" "dns_rg" {
#   count    = var.create_dns_zone && var.dns_resource_group_name != null ? 1 : 0
#   name     = var.dns_resource_group_name
#   location = azurerm_resource_group.rg.location
#   tags     = var.tags
# }

# resource "azurerm_dns_zone" "zone" {
#   count               = var.create_dns_zone ? 1 : 0
#   name                = var.base_domain
#   resource_group_name = local.dns_rg_name
#   tags                = var.tags
# }

# # api.<cluster>.<base_domain> -> public API PIP
# resource "azurerm_dns_a_record" "api" {
#   count               = var.create_dns_zone ? 1 : 0
#   name                = "api.${var.cluster_name}"
#   zone_name           = azurerm_dns_zone.zone[0].name
#   resource_group_name = local.dns_rg_name
#   ttl                 = 60
#   records             = [azurerm_public_ip.pip_api.ip_address]
#   tags                = var.tags
# }

# # *.apps.<cluster>.<base_domain> -> public Ingress PIP
# resource "azurerm_dns_a_record" "apps_wildcard" {
#   count               = var.create_dns_zone ? 1 : 0
#   name                = "*.apps.${var.cluster_name}"
#   zone_name           = azurerm_dns_zone.zone[0].name
#   resource_group_name = local.dns_rg_name
#   ttl                 = 60
#   records             = [azurerm_public_ip.pip_ingress.ip_address]
#   tags                = var.tags
# }