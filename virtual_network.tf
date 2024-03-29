# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Virtual Network definition

resource "azurerm_virtual_network" "aml_vnet" {
  name                = "${var.prefix}-vnet-${random_string.postfix.result}"
  address_space       = ["172.29.0.0/20"]
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
}

resource "azurerm_subnet" "aml_subnet" {
  name                                      = "${var.prefix}-aml-subnet-${random_string.postfix.result}"
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  virtual_network_name                      = azurerm_virtual_network.aml_vnet.name
  address_prefixes                          = ["172.29.0.0/24"]
  service_endpoints                         = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "compute_subnet" {
  name                                      = "${var.prefix}-compute-subnet-${random_string.postfix.result}"
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  virtual_network_name                      = azurerm_virtual_network.aml_vnet.name
  address_prefixes                          = ["172.29.1.0/24"]
  service_endpoints                         = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.prefix}-aks-subnet-${random_string.postfix.result}"
  resource_group_name  = azurerm_resource_group.aml_rg.name
  virtual_network_name = azurerm_virtual_network.aml_vnet.name
  address_prefixes     = ["172.29.4.0/22"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  private_endpoint_network_policies_enabled = true
}

# resource "azurerm_subnet" "bastion_subnet" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.aml_rg.name
#   virtual_network_name = azurerm_virtual_network.aml_vnet.name
#   address_prefixes     = ["10.0.10.0/27"]
# }