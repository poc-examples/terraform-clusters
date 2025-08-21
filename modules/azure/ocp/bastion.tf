########################################
## GENERATE A PUBLIC IP FOR BASTION SERVER
## ACCESS FOR DEBUGGING MACHINES
########################################
resource "azurerm_public_ip" "bastion" {
    name                = "${var.cluster_name}-vnet-bastion-public-ip"
    location            = data.azurerm_resource_group.cluster.location
    resource_group_name = data.azurerm_resource_group.cluster.name
    allocation_method   = "Static"
    sku                 = "Standard"
    tags                = var.tags
}

########################################
## Bastion server requires it's own subnet
## must have the name AzureBastionSubnet
########################################
resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet"
    resource_group_name  = data.azurerm_resource_group.cluster.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes     = ["10.1.0.0/26"]
    # NOTE: No NSG/UDR on this subnet per Azure Bastion requirements.
}

########################################
## Bastion Server with tunneling enabled
## Example Usage:
## az network bastion ssh \
##   --name service-cbe-1-vnet-bastion \
##   --resource-group openenv-n4mcm
##   --target-resource-id "/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.Compute/virtualMachines/<virtual_machine_name>"
##   --auth-type ssh-key \
##   --username core \
##   --ssh-key ~/.ssh/id_rsa
########################################
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
