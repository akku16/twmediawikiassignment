# Resource Group Creation
resource "azurerm_resource_group" "mediawiki-rg" {
    name        = var.resource_group
    location    = var.region
}

# VNet Creation
resource "azurerm_virtual_network" "mediawiki-vnet" {
    name                = "mediawikiVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.region
    resource_group_name = var.resource_group
}

# Subnet Creation
resource "azurerm_subnet" "mediawiki-subnets" {
    count = "${length(var.mediawiki_subnet_var)}"
    name = "${lookup(element(var.mediawiki_subnet_var, count.index), "name")}"
    resource_group_name = var.resource_group
    virtual_network_name = azurerm_virtual_network.mediawiki-vnet.name
    address_prefixes = ["${lookup(element(var.mediawiki_subnet_var, count.index), "ip")}"]
}

# Public IPs creation
resource "azurerm_public_ip" "mediawiki-public-ip" {
    count                   = "${length(var.media_wiki_components)}"
    name                    = "mediawikiPublicIPWeb-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                = var.region
    resource_group_name     = var.resource_group
    allocation_method       = "Dynamic"    
}

# NSG Creation
resource "azurerm_network_security_group" "mediawiki-nsg" {
    count                   = "${length(var.media_wiki_components)}"
    name                    = "mediawikiNSG-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                = var.region
    resource_group_name     = var.resource_group
}


# NSG Rule creation
resource "azurerm_network_security_rule" security_rules {
    count                       = "${length(var.nsg_rules)}"
    depends_on                  = [azurerm_network_security_group.mediawiki-nsg]
    
    name                        = "${lookup(element(var.nsg_rules, count.index), "name")}"
    priority                    = "${lookup(element(var.nsg_rules, count.index), "priority")}"
    direction                   = "${lookup(element(var.nsg_rules, count.index), "direction")}"
    access                      = "${lookup(element(var.nsg_rules, count.index), "access")}"
    protocol                    = "${lookup(element(var.nsg_rules, count.index), "protocol")}"
    source_port_range           = "${lookup(element(var.nsg_rules, count.index), "source_port_range")}"
    destination_port_range      = "${lookup(element(var.nsg_rules, count.index), "destination_port_range")}"
    source_address_prefix       = "${lookup(element(var.nsg_rules, count.index), "source_address_prefix")}"
    destination_address_prefix  = "${lookup(element(var.nsg_rules, count.index), "destination_address_prefix", data.http.ip.body)}"
    
    resource_group_name         = var.resource_group
    network_security_group_name = "mediawikiNSG-${lookup(element(var.nsg_rules, count.index), "nsg_group_name")}"
}


# NIC creation
resource "azurerm_network_interface" "mediawiki-nic" {
    count = "${length(var.media_wiki_components)}"
    name                    = "mediawikiNIC-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                = var.region
    resource_group_name     = var.resource_group

    ip_configuration {
        name                            = "mediawikiNICConfig-${lookup(element(var.media_wiki_components, count.index), "name")}"
        subnet_id                       = azurerm_subnet.mediawiki-subnets[count.index].id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.mediawiki-public-ip[count.index].id
    }
}

# Apply NSG to NIC
resource "azurerm_network_interface_security_group_association" "mediawiki-association" {
    count = "${length(var.media_wiki_components)}"
    network_interface_id = azurerm_network_interface.mediawiki-nic[count.index].id
    network_security_group_id   = azurerm_network_security_group.mediawiki-nsg[count.index].id
}

# VM creation 
resource "azurerm_linux_virtual_machine" "mediawiki-vm" {
    count = "${length(var.media_wiki_components)}"
    name                = "mediawikiVM-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location            = var.region
    resource_group_name = var.resource_group
    network_interface_ids   = [
        azurerm_network_interface.mediawiki-nic[count.index].id
    ]
    size                = "Standard_DS1_v2"
    computer_name       = "mediawikiVM${lookup(element(var.media_wiki_components, count.index), "name")}"
    admin_username      = var.vm_user
    admin_password      = var.vm_user_password
    disable_password_authentication = false

    os_disk {
        name                    = "mediawikiDisk${lookup(element(var.media_wiki_components, count.index), "name")}"
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    tags = {
        type = "${lookup(element(var.media_wiki_components, count.index), "name")}"
    }
}
 

resource "local_file" "mediawiki-hosts-cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      web_hosts = [data.azurerm_public_ip.ip-values[0].ip_address]
      db_hosts  = [data.azurerm_public_ip.ip-values[1].ip_address]
    }
  )
  filename = "../ansible/mediawiki_inventory.ini"
}
