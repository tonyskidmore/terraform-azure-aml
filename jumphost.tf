# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Jump host for testing VNET and Private Link

resource "azurerm_public_ip" "pip" {
  count               = var.create_public_access ? (var.win_vm_deploy == 0 ? 0 : 1) : 0
  name                = "vm-pip-${count.index}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  allocation_method   = "Static"
}

data "http" "ifconfig" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_network_interface" "jumphost_nic" {
  name                = "jumphost-nic"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name

  ip_configuration {
    name                          = "configuration"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.aml_subnet.id
    public_ip_address_id          = var.create_public_access ? element(azurerm_public_ip.pip.*.id, 1) : null
  }
}

resource "azurerm_network_security_group" "jumphost_nsg" {
  name                = "jumphost-nsg"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = local.rdp_source_address_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jumphost_nsg_association" {
  network_interface_id      = azurerm_network_interface.jumphost_nic.id
  network_security_group_id = azurerm_network_security_group.jumphost_nsg.id
}

resource "azurerm_windows_virtual_machine" "winvm" {
  count                 = var.win_vm_deploy
  name                  = "jumphost"
  location              = azurerm_resource_group.aml_rg.location
  resource_group_name   = azurerm_resource_group.aml_rg.name
  network_interface_ids = [azurerm_network_interface.jumphost_nic.id]
  size               = "Standard_DS3_v2"
  admin_username        = var.jumphost_username
  admin_password        = var.jumphost_password

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "dsvm-win-2019"
    sku       = "server-2019"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "jumphost_schedule" {
  virtual_machine_id = azurerm_windows_virtual_machine.winvm[0].id
  location           = azurerm_resource_group.aml_rg.location
  enabled            = true

  daily_recurrence_time = "2000"
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }
}

data "external" "os" {
  working_dir = path.module
  program     = ["printf", "{\"os\": \"Linux\"}"]
}

resource "null_resource" "create_rdp_file" {
  count = var.win_vm_deploy == 0 ? 0 : local.win_check
  provisioner "local-exec" {
    command = "Powershell -file ${path.module}/scripts/New-RdpFile.ps1 -Path ${path.module} -FullAddress ${local.win_ip_address} -Username ${var.jumphost_username} -Password ${var.jumphost_password} -DesktopWidth ${var.rdp_windows_width} -DesktopHeight ${var.rdp_windows_height}"
  }

}

resource "null_resource" "destroy_rdp_file" {
  count = var.win_vm_deploy == 0 ? 0 : local.win_check
  provisioner "local-exec" {
    when    = destroy
    command = "del win_vm.rdp"
  }
}