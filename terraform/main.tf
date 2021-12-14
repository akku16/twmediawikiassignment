# Resource Group Creation
resource "azurerm_resource_group" "mediawiki-rg" {
    name        = "mediawikiResGrp"
    location    = "eastus"

    tags = {
        environment = "TW assignment"
    }
}

# VNet Creation
resource "azurerm_virtual_network" "mediawiki-vnet" {
    name                = "mediawikiVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.mediawikiResGrp.name

    tags = {
        environment = "TW assignment"
    }
}

# Subnet Creation
resource "azurerm_subnet" "mediawiki-subnet" {
    name                    = "mediawikiSubnet"
    resource_group_name     = azurerm_resource_group.mediawikiResGrp.name
    virtual_network_name    = azurerm_virtual_network.mediawikiVnet.name
    address_prefixes        = ["10.0.1.0/24"]
}

# Public IPs creation
resource "azurerm_public_ip" "mediawiki-public-ip" {
    name                    = "mediawikiPublicIP"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawikiResGrp.name
    allocation_method       = "Dynamic"    
}