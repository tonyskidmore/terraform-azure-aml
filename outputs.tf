# output "my_ip_address" {
#   value       = local.rdp_source_address_prefix
#   description = "Source IP address from online service"
# }

# output "winvm_private_ip" {
#   value       = try(azurerm_windows_virtual_machine.winvm[0].private_ip_address, null)
#   description = "Windows VM private IP address"
# }

# output "winvm_public_ip" {
#   value       = try(azurerm_windows_virtual_machine.winvm.*.public_ip_address[0], null)
#   description = "Windows VM public IP address"
# }

output "resource_group_name" {
  value = azurerm_resource_group.aml_rg.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.aml_aks.name
}

output "prefix" {
  value = var.prefix
}

output "postfix" {
  value = random_string.postfix.result
}
