variable "storage_account_name" {
  type    = string
  default = "mediawikisa"
  }

variable "resource_group" {
  type  = string
  default = "mediawikiResGrp"
}

variable "region" {
  type  = string
  default = "eastus"
}

variable "vm_user" {
  type = string 
  description = "Picked from ENV variables. Define then as TF_VAR_vm_user"
}

variable "SUBSCRIPTION_ID" {
  type = string
}

variable "TENANT_ID" {
  type = string
}

variable "CLIENT_ID" {
  type = string
}

variable "CLIENT_SECRET" {
  type = string
}

variable "mediawiki_subnet_var" {
  type = list
  default = [
    {
      ip      = "10.0.1.0/24"
      name    = "mediawikiSubnet-web"
    },
    {
      ip      = "10.0.2.0/24"
      name    = "mediawikiSubnet-db"
    }
   ]
}

variable "media_wiki_components" {
  type = list
  default = [
    {
      name  = "web"
    },
    { 
      name  = "db"
    }
  ]
}

variable "nsg_rules" {
  type = list
  default = [
    {
      name = "ssh"
      priority = 1001
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "22"
      source_address_prefix = "*"
      destination_address_prefix = "*"
      nsg_group_name = "web"
    },
    {
      name = "ssh"
      priority = 1001
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "22"
      source_address_prefix = "*"
      destination_address_prefix = "*"
      nsg_group_name = "db"
    },
    {
      name = "http"
      priority = 1002
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "80"
      source_address_prefix = "*"
      destination_address_prefix = "*"
      nsg_group_name = "web"
    },
    {
      name = "dbaccess"
      priority = 1003
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "3306"
      source_address_prefix = "10.0.1.0/24"
      destination_address_prefix = "10.0.2.0/24"
      nsg_group_name = "db"
    }
  ]
}
