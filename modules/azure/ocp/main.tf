###############
## START
###############
data "azurerm_resource_group" "cluster" {
    name     = var.resource_group_name
}

# --------------------------
# Networking: VNet + Subnets
# --------------------------
resource "azurerm_virtual_network" "network" {
    name                = "${var.cluster_name}-vnet"
    address_space       = ["10.0.0.0/22", "10.1.0.0/24"]
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

resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet"
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.1.0.0/26"]
    # NOTE: No NSG/UDR on this subnet per Azure Bastion requirements.
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
            # SSH 22
            {
                name                   = "allow-ssh-22"
                priority               = 130
                direction              = "Inbound"
                access                 = "Allow"
                protocol               = "Tcp"
                source_port_range      = "*"
                destination_port_range = "22"
                source_address_prefix  = "*"
                destination_address_prefix = "*"
            },
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
                source_address_prefix  = "VirtualNetwork"
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

resource "azurerm_public_ip" "bastion" {
    name                = "${var.cluster_name}-vnet-bastion-public-ip"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

# --------------------------
# Bastion Host
# --------------------------
resource "azurerm_bastion_host" "this" {
    name                = "${var.cluster_name}-vnet-bastion"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    sku                 = "Standard"
    tunneling_enabled   = true
    tags                = var.tags

    ip_configuration {
        name                 = "configuration"
        subnet_id            = azurerm_subnet.bastion.id
        public_ip_address_id = azurerm_public_ip.bastion.id
    }
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


# --------------------------
# Load Balancer
# --------------------------
# Internal API/MCS LB (6443 + 22623)
resource "azurerm_lb" "lb_api_internal" {
    name                = "${var.cluster_name}-lb-api-internal"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    sku                 = "Standard"
    tags                = var.tags

    frontend_ip_configuration {
        name                          = "fe"
        subnet_id                     = azurerm_subnet.control_plane.id
        private_ip_address_allocation = "Static"
        private_ip_address            = var.api_int_lb_ip
    }
}

resource "azurerm_lb_backend_address_pool" "lbp_api_internal" {
    name            = "be"
    loadbalancer_id = azurerm_lb.lb_api_internal.id
}

resource "azurerm_lb_probe" "probe_api_int_6443" {
  name                = "tcp-6443"
  loadbalancer_id     = azurerm_lb.lb_api_internal.id
  protocol            = "Tcp"
  port                = 6443
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "probe_mcs_22623" {
  name                = "tcp-22623"
  loadbalancer_id     = azurerm_lb.lb_api_internal.id
  protocol            = "Tcp"
  port                = 22623
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "rule_api_int_6443" {
    name                           = "api-int-6443"
    loadbalancer_id                = azurerm_lb.lb_api_internal.id
    protocol                       = "Tcp"
    frontend_port                  = 6443
    backend_port                   = 6443
    frontend_ip_configuration_name = "fe"
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_internal.id]
    # probe_id                       = azurerm_lb_probe.probe_api_int_6443.id
}

resource "azurerm_lb_rule" "rule_mcs_22623" {
    name                           = "mcs-22623"
    loadbalancer_id                = azurerm_lb.lb_api_internal.id
    protocol                       = "Tcp"
    frontend_port                  = 22623
    backend_port                   = 22623
    frontend_ip_configuration_name = "fe"
    backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lbp_api_internal.id]
    # probe_id                       = azurerm_lb_probe.probe_mcs_22623.id
}

# --------------------------
# Public DNS
# --------------------------
resource "azurerm_dns_zone" "zone" {
    name                = "objectworksit.com"
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags
}

# api.<cluster>.<base_domain> -> public API Public IP
resource "azurerm_dns_a_record" "api" {
    name                = "api.${var.cluster_name}"
    zone_name           = azurerm_dns_zone.zone.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [azurerm_public_ip.public_ip_api.ip_address]
    tags                = var.tags
}

# *.apps.<cluster>.<base_domain> -> public Ingress Public IP
resource "azurerm_dns_a_record" "apps_wildcard" {
    name                = "*.apps.${var.cluster_name}"
    zone_name           = azurerm_dns_zone.zone.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [azurerm_public_ip.public_ip_ingress.ip_address]
    tags                = var.tags
}


# --------------------------
# Private DNS for api-int
# --------------------------
resource "azurerm_private_dns_zone" "base" {
    name                = "objectworksit.com"
    resource_group_name = data.azurerm_resource_group.cluster.name
    tags                = var.tags
}

# Link the private zone to the cluster VNet so VMs resolve it
resource "azurerm_private_dns_zone_virtual_network_link" "base_link" {
    name                  = "${var.cluster_name}-privdns-link"
    resource_group_name   = data.azurerm_resource_group.cluster.name
    private_dns_zone_name = azurerm_private_dns_zone.base.name
    virtual_network_id    = azurerm_virtual_network.network.id
    registration_enabled  = false
}

# api-int.<cluster>.objectworksit.com -> Internal API LB IP
resource "azurerm_private_dns_a_record" "api_int" {
    name                = "api-int.${var.cluster_name}"
    zone_name           = azurerm_private_dns_zone.base.name
    resource_group_name = data.azurerm_resource_group.cluster.name
    ttl                 = 60
    records             = [var.api_int_lb_ip]
    tags                = var.tags
}


# ---------------------------
# Storage for Ignition Configs
# ---------------------------
resource "time_static" "now" {}

resource "azurerm_storage_account" "ign" {
    name                     = substr(lower(replace("${var.cluster_name}ignservicecbe", "/[^a-z0-9]/", "")), 0, 24)
    resource_group_name      = data.azurerm_resource_group.cluster.name
    location                 = data.azurerm_resource_group.cluster.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    allow_nested_items_to_be_public = false

}

resource "azurerm_storage_container" "ign" {
    name                  = "ignition"
    storage_account_name  = azurerm_storage_account.ign.name
    container_access_type = "private"
}

# Read-only SAS for the container (start a bit in the past to avoid clock skew)
data "azurerm_storage_account_sas" "ign_ro" {
  connection_string = azurerm_storage_account.ign.primary_connection_string
  https_only        = true

  # start a bit in the past to avoid clock skew
  start  = timeadd(time_static.now.rfc3339, "-15m")
  expiry = timeadd(time_static.now.rfc3339, "168h") # 7 days

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  resource_types {
    service   = true
    container = true
    object    = true
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }

  # Optional but harmless to pin:
  # signed_version = "2020-08-04"
}

locals {
    ign_base       = "https://${azurerm_storage_account.ign.name}.blob.core.windows.net/${azurerm_storage_container.ign.name}"
    bootstrap_url  = "${local.ign_base}/bootstrap.ign?${data.azurerm_storage_account_sas.ign_ro.sas}"
    master_url     = "${local.ign_base}/master.ign?${data.azurerm_storage_account_sas.ign_ro.sas}"
    worker_url     = "${local.ign_base}/worker.ign?${data.azurerm_storage_account_sas.ign_ro.sas}"
}

locals {
    bootstrap_custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.bootstrap_url } }
        }
    }))

    master_custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.master_url } }
        }
    }))

    worker_custom_data = base64encode(jsonencode({
        ignition = {
            version = "3.2.0"
            config  = { replace = { source = local.worker_url } }
        }
    }))
}

###
## DEPLOY VMS
##
variable "master_count" { 
    type = number 
    default = 3 
}
variable "worker_count" { 
    type = number 
    default = 3 
}

resource "azurerm_marketplace_agreement" "rhcos" {
    publisher = "redhat"
    offer     = "rh-ocp-worker"
    plan      = "rh-ocp-worker"
}

locals {
    rhcos_publisher = "redhat"
    rhcos_offer     = "rh-ocp-worker"
    rhcos_sku       = "rh-ocp-worker"
    rhcos_version   = "4.18.2025031114"
}

locals {
    ssh_pubkey = file("/usr/src/app/terraform/id_rsa.pub")
}

##
## Bootstrap Machine
##
resource "azurerm_network_interface" "bootstrap" {
    name                = "${var.cluster_name}-ni-bootstrap"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    ip_configuration {
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.control_plane.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "bootstrap" {
    name                = "${var.cluster_name}-vm-bootstrap"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    size                = "Standard_D8s_v3"
    admin_username      = "core"
    network_interface_ids = [azurerm_network_interface.bootstrap.id]

    source_image_reference {
        publisher = local.rhcos_publisher
        offer     = local.rhcos_offer
        sku       = local.rhcos_sku
        version   = local.rhcos_version
    }

    admin_ssh_key {
        username   = "core"
        public_key = local.ssh_pubkey
    }

    plan {
        name      = "rh-ocp-worker"
        product   = "rh-ocp-worker"
        publisher = "redhat"
    }

    custom_data = local.bootstrap_custom_data

    os_disk {
        name                 = "${var.cluster_name}-os-bootstrap"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = "1000"
    }
}

#
# MASTERS
#
resource "azurerm_network_interface" "master" {
    count               = var.master_count
    name                = "${var.cluster_name}-ni-master-${count.index}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    ip_configuration {
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.control_plane.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "master" {
    count               = var.master_count
    name                = "${var.cluster_name}-vm-master-${count.index}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    size                = "Standard_D8s_v3"
    admin_username      = "core"
    network_interface_ids = [azurerm_network_interface.master[count.index].id]

    source_image_reference {
        publisher = local.rhcos_publisher
        offer     = local.rhcos_offer
        sku       = local.rhcos_sku
        version   = local.rhcos_version
    }

    admin_ssh_key {
        username   = "core"
        public_key = local.ssh_pubkey
    }

    plan {
        name      = "rh-ocp-worker"
        product   = "rh-ocp-worker"
        publisher = "redhat"
    }

    custom_data = local.master_custom_data

    os_disk {
        name                 = "${var.cluster_name}-os-master-${count.index}"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = "1000"
    }
}

#
# Workers
#
resource "azurerm_network_interface" "worker" {
    count               = var.worker_count
    name                = "${var.cluster_name}-ni-worker-${count.index}"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    ip_configuration {
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.worker_subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}

# resource "azurerm_linux_virtual_machine" "worker" {
#     count               = var.worker_count
#     name                = "${var.cluster_name}-vm-worker-${count.index}"
#     location            = data.azurerm_resource_group.cluster.location
#     resource_group_name = data.azurerm_resource_group.cluster.name
#     size                = "Standard_D8s_v3"
#     admin_username      = "core"
#     network_interface_ids = [azurerm_network_interface.worker[count.index].id]

#     source_image_reference {
#         publisher = local.rhcos_publisher
#         offer     = local.rhcos_offer
#         sku       = local.rhcos_sku
#         version   = local.rhcos_version
#     }

#     admin_ssh_key {
#         username   = "core"
#         public_key = local.ssh_pubkey
#     }

#     plan {
#         name      = "rh-ocp-worker"
#         product   = "rh-ocp-worker"
#         publisher = "redhat"
#     }

#     custom_data = local.worker_custom_data

#     os_disk {
#         name                 = "${var.cluster_name}-os-worker-${count.index}"
#         caching              = "ReadWrite"
#         storage_account_type = "Premium_LRS"
#     }
# }

#
# ip pool associations
#
# Bootstrap to API internal + public (only while bootstrapping)
resource "azurerm_network_interface_backend_address_pool_association" "bootstrap_api_public" {
  network_interface_id    = azurerm_network_interface.bootstrap.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_api_public.id
}
resource "azurerm_network_interface_backend_address_pool_association" "bootstrap_api_internal" {
  network_interface_id    = azurerm_network_interface.bootstrap.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_api_internal.id
}

# Masters to API internal + public
resource "azurerm_network_interface_backend_address_pool_association" "masters_api_public" {
  for_each                = { for i, nic in azurerm_network_interface.master : i => nic.id }
  network_interface_id    = each.value
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_api_public.id
}
resource "azurerm_network_interface_backend_address_pool_association" "masters_api_internal" {
  for_each                = { for i, nic in azurerm_network_interface.master : i => nic.id }
  network_interface_id    = each.value
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_api_internal.id
}

# Workers to public ingress LB
resource "azurerm_network_interface_backend_address_pool_association" "workers_ingress_public" {
  for_each                = { for i, nic in azurerm_network_interface.worker : i => nic.id }
  network_interface_id    = each.value
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lbp_ingress_public.id
}
