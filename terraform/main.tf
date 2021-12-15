# Resource Group Creation
resource "azurerm_resource_group" "mediawiki-rg" {
    name        = "mediawikiResGrp"
    location    = "eastus"
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
resource "azurerm_subnet" "mediawiki-subnet-web" {
    name                    = "mediawikiSubnetWeb"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    virtual_network_name    = azurerm_virtual_network.mediawiki-vnet.name
    address_prefixes        = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "mediawiki-subnet-db" {
    name                    = "mediawikiSubnetDb"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    virtual_network_name    = azurerm_virtual_network.mediawiki-vnet.name
    address_prefixes        = ["10.0.2.0/24"]
}
# Public IPs creation
resource "azurerm_public_ip" "mediawiki-public-ip-web" {
    name                    = "mediawikiPublicIPWeb"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    allocation_method       = "Dynamic"    
}

resource "azurerm_public_ip" "mediawiki-public-ip-db" {
    name                    = "mediawikiPublicIPDb"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    allocation_method       = "Dynamic"    
}

# NSG Creation
resource "azurerm_network_security_group" "mediawiki-nsg-web" {
    name                    = "mediawikiNSGWeb"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
}

resource "azurerm_network_security_group" "mediawiki-nsg-db" {
    name                    = "mediawikiNSGDb"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
}  

# NSG Rule creation
resource "azurerm_network_security_rule" security_rule1_web {

        depends_on                 = [azurerm_network_security_group.mediawiki-nsg-web]
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*" 
        resource_group_name         = azurerm_resource_group.mediawiki-rg.name
        network_security_group_name = azurerm_network_security_group.mediawiki-nsg-web.name
}

resource "azurerm_network_security_rule" security_rule1_db {

        depends_on                 = [azurerm_network_security_group.mediawiki-nsg-db]
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*" 
        resource_group_name         = azurerm_resource_group.mediawiki-rg.name
        network_security_group_name = azurerm_network_security_group.mediawiki-nsg-db.name
}

resource "azurerm_network_security_rule" security_rule2 {
        depends_on                  = [azurerm_network_security_group.mediawiki-nsg-web]
        name                        = "http"
        priority                    = 1002
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "8080"
        source_address_prefix       = "*"
        destination_address_prefix  = "*" 
        resource_group_name         = azurerm_resource_group.mediawiki-rg.name
        network_security_group_name = azurerm_network_security_group.mediawiki-nsg-web.name
}

# NIC creation
resource "azurerm_network_interface" "mediawiki-nic-web" {
    name                    = "mediawikiNICWeb"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    
    ip_configuration {
        name                            = "mediawikiNICConfigWeb"
        subnet_id                       = azurerm_subnet.mediawiki-subnet-web.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.mediawiki-public-ip-web.id
    }
}

resource "azurerm_network_interface" "mediawiki-nic-db" {
    name                    = "mediawikiNICDb"
    location                = "eastus"
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    
    ip_configuration {
        name                            = "mediawikiNICConfigDb"
        subnet_id                       = azurerm_subnet.mediawiki-subnet-db.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.mediawiki-public-ip-db.id
    }
}

# Apply NSG to NIC
resource "azurerm_network_interface_security_group_association" "mediawiki-association-web" {
    network_interface_id = azurerm_network_interface.mediawiki-nic-web.id
    network_security_group_id   = azurerm_network_security_group.mediawiki-nsg-web.id
}

resource "azurerm_network_interface_security_group_association" "mediawiki-association-db" {
    network_interface_id = azurerm_network_interface.mediawiki-nic-db.id
    network_security_group_id   = azurerm_network_security_group.mediawiki-nsg-db.id
}

# VM creation 
resource "azurerm_linux_virtual_machine" "mediawiki-vm-web" {
    name                = "mediawikiVMWeb"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
    network_interface_ids   = [
        azurerm_network_interface.mediawiki-nic-web.id
    ]
    size                = "Standard_DS1_v2"

    os_disk {
        name                    = "mediawikiDiskWeb"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "mediawikiVMWeb"
    admin_username = "akshar"
    admin_password = "Welcome@123"
    disable_password_authentication = false

    tags = {
        type = "web"
    }
}

resource "azurerm_linux_virtual_machine" "mediawiki-vm-db" {
    name                = "mediawikiVMDb"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
    network_interface_ids   = [
        azurerm_network_interface.mediawiki-nic-db.id
    ]
    size                = "Standard_DS1_v2"

    os_disk {
        name                    = "mediawikiDiskDb"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "mediawikiVMDb"
    admin_username = "akshar"
    admin_password = "Welcome@123"
    disable_password_authentication = false

    tags = {
        type = "db"
    }
}

data "azurerm_public_ip" "test-web" {
    depends_on          = [azurerm_linux_virtual_machine.mediawiki-vm-web]
    name                = azurerm_public_ip.mediawiki-public-ip-web.name
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
}

data "azurerm_public_ip" "test-db" {
    depends_on          = [azurerm_linux_virtual_machine.mediawiki-vm-db]
    name                = azurerm_public_ip.mediawiki-public-ip-db.name
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
}

resource "local_file" "mediawiki-hosts-cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      web_hosts = [data.azurerm_public_ip.test-web.ip_address]
      db_hosts  = [data.azurerm_public_ip.test-db.ip_address]
    }
  )
  filename = "../ansible/mediawiki_inventory.ini"
}