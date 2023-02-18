# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Key Vault with VNET binding and Private Endpoint

# Issue deploying
# │ Error: waiting for Vault: (Name "aml-kv-fxgxom" / Resource Group "rg-aml-terraform-demo") to become available: connecting to "https://aml-kv-fxgxom.vault.azure.net/": Get "https://aml-kv-fxgxom.vault.azure.net/": EOF
# │ 
# │   with azurerm_key_vault.aml_kv,
# │   on key_vault.tf line 8, in resource "azurerm_key_vault" "aml_kv":
# │    8: resource "azurerm_key_vault" "aml_kv" {
# │ 
# https://github.com/hashicorp/terraform-provider-azurerm/issues/18309 
# Has worked on retrying the plan


resource "azurerm_key_vault" "aml_kv" {
  name                = "${var.prefix}-kv-${random_string.postfix.result}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [azurerm_subnet.aml_subnet.id, azurerm_subnet.compute_subnet.id, azurerm_subnet.aks_subnet.id]
    bypass                     = "AzureServices"
  }

  timeouts {
    create = "1h"
    read   = "15m"
    update = "1h"
    delete = "1h"
  }

  # defaults
  # timeouts {
  #   create = "30m"
  #   read   = "5m"
  #   update = "30m"
  #   delete = "30m"
  # }

}

# DNS Zones

resource "azurerm_private_dns_zone" "kv_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.aml_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "kv_zone_link" {
  name                  = "${random_string.postfix.result}_link_kv"
  resource_group_name   = azurerm_resource_group.aml_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.prefix}-kv-pe-${random_string.postfix.result}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  subnet_id           = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-kv-psc-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_key_vault.aml_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_zone.id]
  }
}