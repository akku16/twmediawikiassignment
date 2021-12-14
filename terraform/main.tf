resource "azurerm_resource_group" "mediawiki-rg" {
    name        = "mediawikiResGrp"
    location    = "eastus"

    tags - {
        environment = "TW assignment"
    }
}