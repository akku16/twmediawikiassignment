data "azurerm_public_ip" "ip-values" {
    count = "${length(var.media_wiki_components)}"
    depends_on          = [azurerm_linux_virtual_machine.mediawiki-vm]
    
    name                = azurerm_public_ip.mediawiki-public-ip[count.index].name
    resource_group_name = var.resource_group
}

data "http" "ip" {
  url = "https://ifconfig.me"
}