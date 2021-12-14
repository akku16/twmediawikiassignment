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

# NSG Creation
resource "azurerm_network_security_group" "mediawiki-nsg" {
    name            = "mediawikiNSG"
    location        = "eastus"
    resource_group_name     = azurerm_resource_group.mediawikiResGrp.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*" 
    }
}

# NIC creation
resource "azurerm_network_interface" "mediawiki-nic" {
    name                    = "mediawikiNIC"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawikiResGrp.name
    
    ip_configuration {
        name                            = "mediawikiNICConfig"
        subnet_id                       = azurerm_subnet.mediawikiSubnet.name
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.mediawikiPublicIP.name
    }
}
