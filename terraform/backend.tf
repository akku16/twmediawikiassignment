terraform {
    backend "azurerm" {
        resource_group_name  = var.resource_group
        storage_account_name = var.storage_account_name
        container_name       = var.container_name
        key                  = var.key      
    }
}