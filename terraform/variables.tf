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

variable "vm_user_password" {
  type = string
  description = "Picked from ENV variables. Define then as TF_VAR_vm_user_password"
}

# variable "mediawiki_subnet_var" {
#   type = list
#   default = [
#     {
#       ip      = "10.0.1.0/24"
#       name    = "mediawikiSubnet-1"
#     },
#     {
#       ip      = "10.0.2.0/24"
#       name    = "mediawikiSubnet-2"
#     },
#     {
#       ip      = "10.0.3.0/24"
#       name    = "mediawikiSubnet-3"
#     }
#    ]
# }

# variable "media_wiki_components" {
#   type = list
#   default = ["web", "db"]
# }
