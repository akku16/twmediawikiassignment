terraform {
    backend "azurerm" {
        resource_group_name  = "mediawiki-storage-account-rg"
        storage_account_name = "aksss1234572"
        container_name       = "terraform"
        key                  = "terraform.tfstate"      
    }
}