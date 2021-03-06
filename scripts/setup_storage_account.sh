#!/bin/bash

echo "====> Creation of storage accoung for terraform backend"
RESOURCE_GROUP_NAME=mediawiki-storage-account-rg
STORAGE_ACCOUNT_NAME=aksss1234572
CONTAINER_NAME=terraform

echo "Create resource group"
az group create --name $RESOURCE_GROUP_NAME --location eastus && echo "===> Resource Group created successfully" || exit 1

echo "Create storage account"
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob && echo "===> Storage Account created successfully" || exit 1

# echo "Get storage account key"
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv) && echo "===> Key fetchedsuccessfully" || exit 1

echo "Create container"
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY && echo "===> Container created successfully" || exit 1
echo "========================"
echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
echo "container_name: $CONTAINER_NAME"
echo "access_key: $ACCOUNT_KEY"
