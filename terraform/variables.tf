variable "storage_account_name" {
  type    = string
  default = "mediawikisa"
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

variable "media_wiki_components" {
  type = list
  default = ["web", "db"]
}