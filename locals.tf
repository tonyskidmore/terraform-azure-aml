locals {
  rdp_source_address_prefix = var.mgmt_rdp_source_address_prefix == "" ? data.http.ifconfig.response_body : var.mgmt_rdp_source_address_prefix
  win_check                 = data.external.os.result.os == "Windows" ? 1 : 0
  win_ip_address            = try(var.create_public_access ? azurerm_windows_virtual_machine.winvm.*.public_ip_address[0] : azurerm_windows_virtual_machine.winvm[0].private_ip_address, "")
}