terraform {
    backend "azurerm" {
        resource_group_name  = "mediawiki-storage-account-rg"
        storage_account_name = "aksss1234572"
        container_name       = "terraform"
        key                  = "230DmiyIla17tAr8Qijaf489DtYKWJ5bl817567HRbq8JZXer9sRFR8aLUU+hDETo2B/GSyWvPt1gm0P0T4Tdw=="      
    }
}