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
    resource_group_name = azurerm_resource_group.mediawiki-rg.name

    tags = {
        environment = "TW assignment"
    }
}

# Subnet Creation
resource "azurerm_subnet" "mediawiki-subnet" {
    name                    = "mediawikiSubnet"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    virtual_network_name    = azurerm_virtual_network.mediawiki-vnet.name
    address_prefixes        = ["10.0.1.0/24"]
}

# Public IPs creation
resource "azurerm_public_ip" "mediawiki-public-ip" {
    name                    = "mediawikiPublicIP"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    allocation_method       = "Dynamic"    
}

# NSG Creation
resource "azurerm_network_security_group" "mediawiki-nsg" {
    name                    = "mediawikiNSG"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    
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
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    
    ip_configuration {
        name                            = "mediawikiNICConfig"
        subnet_id                       = azurerm_subnet.mediawiki-subnet.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.mediawiki-public-ip.id
    }
}

# Apply NSG to NIC
resource "azurerm_network_interface_security_group_association" "mediawiki-association" {
    network_interface_id = azurerm_network_interface.mediawiki-nic.id
    network_security_group_id   = azurerm_network_security_group.mediawiki-nsg.id
}

# Storage Account creation
resource "azurerm_storage_account" "mediawiki-storage-account" {
    name                        = var.storage_account_name
    resource_group_name         = azurerm_resource_group.mediawiki-rg.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

# # Login Key creation
# resource "tls_private_key" "mediawiki-key" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }
# output "tls_private_key" { 
#     value = tls_private_key.mediawiki-key.private_key_pem 
#     sensitive = true
# }

# VM creation 
resource "azurerm_linux_virtual_machine" "mediawiki-vm" {
    name                = "mediawikiVM"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
    network_interface_ids   = [
        azurerm_network_interface.mediawiki-nic.id
    ]
    size                = "Standard_DS1_v2"

    os_disk {
        name                    = "mediawikiDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "mediawikiVM"
    admin_username = "akshar"
    admin_password = "Welcome@123"
    disable_password_authentication = false
}