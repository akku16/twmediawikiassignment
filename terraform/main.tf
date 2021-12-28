# Resource Group Creation
resource "azurerm_resource_group" "mediawiki-rg" {
    name        = var.resource_group
    location    = var.region
}

# Key Creation
resource "tls_private_key" "mediawiki-ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Keyvault name generator
resource "random_string" "kv-name" {
  length           = 16
  special          = false
  number           = false
}

# Keyvault creation
resource "azurerm_key_vault" "mediawiki-kv" {
  name                        = random_string.kv-name.result
  location                    = var.region
  resource_group_name         = azurerm_resource_group.mediawiki-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
        "set",
        "get",
        "delete",
        "purge",
        "recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

# Random password 
resource "random_password" "password" {
  length           = 16
  special          = true
}

# Secret addition
resource "azurerm_key_vault_secret" "mediawiki-user-pwd" {
  name         = "tw-password"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.mediawiki-kv.id
}

# VNet Creation
resource "azurerm_virtual_network" "mediawiki-vnet" {
    name                = "mediawikiVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.region
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
}

# Subnet Creation
resource "azurerm_subnet" "mediawiki-subnets" {
    count = "${length(var.mediawiki_subnet_var)}"
    name = "${lookup(element(var.mediawiki_subnet_var, count.index), "name")}"
    resource_group_name = azurerm_resource_group.mediawiki-rg.name
    virtual_network_name = azurerm_virtual_network.mediawiki-vnet.name
    address_prefixes = ["${lookup(element(var.mediawiki_subnet_var, count.index), "ip")}"]
}

# Public IPs creation
resource "azurerm_public_ip" "mediawiki-public-ip" {
    count                   = "${length(var.media_wiki_components)}"
    name                    = "mediawikiPublicIPWeb-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                = var.region
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
    allocation_method       = "Dynamic"    
}

# NSG Creation
resource "azurerm_network_security_group" "mediawiki-nsg" {
    count                   = "${length(var.media_wiki_components)}"
    name                    = "mediawikiNSG-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                = var.region
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name
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
    source_address_prefix       = "${lookup(element(var.nsg_rules, count.index), "source_address_prefix", data.http.ip.body)}"
    destination_address_prefix  = "${lookup(element(var.nsg_rules, count.index), "destination_address_prefix")}"
    
    resource_group_name         = azurerm_resource_group.mediawiki-rg.name
    network_security_group_name = "mediawikiNSG-${lookup(element(var.nsg_rules, count.index), "nsg_group_name")}"
}

# NIC creation
resource "azurerm_network_interface" "mediawiki-nic" {
    count                   = "${length(var.media_wiki_components)}"
    name                    = "mediawikiNIC-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                = var.region
    resource_group_name     = azurerm_resource_group.mediawiki-rg.name

    ip_configuration {
        name                            = "mediawikiNICConfig-${lookup(element(var.media_wiki_components, count.index), "name")}"
        subnet_id                       = azurerm_subnet.mediawiki-subnets[count.index].id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.mediawiki-public-ip[count.index].id
    }
}

# Apply NSG to NIC
resource "azurerm_network_interface_security_group_association" "mediawiki-association" {
    count                       = "${length(var.media_wiki_components)}"
    network_interface_id        = azurerm_network_interface.mediawiki-nic[count.index].id
    network_security_group_id   = azurerm_network_security_group.mediawiki-nsg[count.index].id
}

# VM creation 
resource "azurerm_linux_virtual_machine" "mediawiki-vm" {
    count                           = "${length(var.media_wiki_components)}"
    name                            = "mediawikiVM-${lookup(element(var.media_wiki_components, count.index), "name")}"
    location                        = var.region
    resource_group_name             = azurerm_resource_group.mediawiki-rg.name
    network_interface_ids           = [azurerm_network_interface.mediawiki-nic[count.index].id]
    size                            = "Standard_DS1_v2"
    computer_name                   = "mediawikiVM${lookup(element(var.media_wiki_components, count.index), "name")}"
    admin_username                  = var.vm_user
    #admin_password                  = var.vm_user_password
    disable_password_authentication = true

    admin_ssh_key {
        username       = var.vm_user
        public_key     = tls_private_key.mediawiki-ssh.public_key_openssh
    }

    os_disk {
        name                    = "mediawikiDisk-${lookup(element(var.media_wiki_components, count.index), "name")}"
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

# Ansible inventory file creation
resource "local_file" "mediawiki-hosts-cfg" {
  content   = templatefile("${path.module}/templates/hosts.tpl",
    {
      web_hosts = [data.azurerm_public_ip.ip-values[0].ip_address]
      db_hosts  = [data.azurerm_public_ip.ip-values[1].ip_address]
    }
  )
  filename = "../ansible/mediawiki_inventory.ini"
}

# Private key file creation
resource "local_file" "private_key" {
  content         = tls_private_key.mediawiki-ssh.private_key_pem
  filename        = "../files/id_rsa"
  file_permission = "0600"
}

# Running ansible playbook parallely
resource "null_resource" "ansible-command" {
    depends_on = [
                    azurerm_linux_virtual_machine.mediawiki-vm,
                    azurerm_key_vault.mediawiki-kv,
                    local_file.mediawiki-hosts-cfg
                 ]
    
    count = "${length(var.media_wiki_components)}"
    provisioner "local-exec" {
        #command = "cd ../ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i mediawiki_inventory.ini deploy.yml -e rg_name=${azurerm_resource_group.mediawiki-rg.name} -e kv_name=${random_string.kv-name.result} --tags ${lookup(element(var.media_wiki_components, count.index), "name")}"
        command = "cd ../ansible && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i mediawiki_inventory.ini deploy.yml --tags ${lookup(element(var.media_wiki_components, count.index), "name")}"
  }
}
