# output "public_ip_address" {
#   value = data.azurerm_public_ip.test.ip_address
# }

# output "private_ip_address" {
#     value = azurerm_network_interface.mediawiki-nic.private_ip_address
# }

# output "aks" {
#     value = "awesome"
# }

output "pem" {
        value = [tls_private_key.mediawiki-key.private_key_pem]
        sensitive = true
}