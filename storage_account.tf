# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Storage Account with VNET binding and Private Endpoint for Blob and File

resource "azurerm_storage_account" "aml_sa" {
  name                     = "${var.prefix}sa${random_string.postfix.result}"
  location                 = azurerm_resource_group.aml_rg.location
  resource_group_name      = azurerm_resource_group.aml_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "aml_train_data" {
  name                     = "${var.prefix}satraindata${random_string.postfix.result}"
  location                 = azurerm_resource_group.aml_rg.location
  resource_group_name      = azurerm_resource_group.aml_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.aml_train_data.id

  rule {
    name    = "MoveToCool"
    enabled = true
    filters {
      # prefix_match = ["container1/prefix1"]
      blob_types   = ["blockBlob"]
      # match_blob_index_tag {
      #   name      = "tag1"
      #   operation = "=="
      #   value     = "val1"
      # }
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_creation_greater_than = 1
      }
    }
  }
  rule {
    name    = "MoveToArchive"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_archive_after_days_since_creation_greater_than = 5
      }
    }
  }
  rule {
    name    = "Delete"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 6
      }
    }
  }
}


resource "azurerm_storage_container" "model_training_data" {
  name                  = "model-training-data"
  storage_account_name  = azurerm_storage_account.aml_train_data.name
  container_access_type = "private"
}

# Virtual Network & Firewall configuration

resource "azurerm_storage_account_network_rules" "firewall_rules" {
  storage_account_id = azurerm_storage_account.aml_sa.id
  # resource_group_name  = azurerm_resource_group.aml_rg.name
  # storage_account_name = azurerm_storage_account.aml_sa.name

  default_action             = "Deny"
  ip_rules                   = ["62.254.63.52"]
  virtual_network_subnet_ids = [azurerm_subnet.aml_subnet.id, azurerm_subnet.compute_subnet.id, azurerm_subnet.aks_subnet.id]
  bypass                     = ["AzureServices"]

  # Set network policies after Workspace has been created (will create File Share Datastore properly)
  depends_on = [azurerm_machine_learning_workspace.aml_ws]
}

# resource "azurerm_storage_account_network_rules" "firewall_rules" {
#   storage_account_id = azurerm_storage_account.aml_sa.id
#   # resource_group_name  = azurerm_resource_group.aml_rg.name
#   # storage_account_name = azurerm_storage_account.aml_sa.name

#   default_action             = "Deny"
#   ip_rules                   = []
#   virtual_network_subnet_ids = [azurerm_subnet.aml_subnet.id, azurerm_subnet.compute_subnet.id, azurerm_subnet.aks_subnet.id]
#   bypass                     = ["AzureServices"]

#   # Set network policies after Workspace has been created (will create File Share Datastore properly)
#   depends_on = [azurerm_machine_learning_workspace.aml_ws]
# }

resource "azurerm_storage_account_network_rules" "firewall_rules_train" {
  storage_account_id = azurerm_storage_account.aml_train_data.id
  # resource_group_name  = azurerm_resource_group.aml_rg.name
  # storage_account_name = azurerm_storage_account.aml_sa.name

  default_action             = "Deny"
  ip_rules                   = ["62.254.63.52"]
  virtual_network_subnet_ids = [azurerm_subnet.aml_subnet.id, azurerm_subnet.compute_subnet.id, azurerm_subnet.aks_subnet.id]
  bypass                     = ["AzureServices"]

  # Set network policies after Workspace has been created (will create File Share Datastore properly)
  depends_on = [azurerm_machine_learning_workspace.aml_ws]
}

# DNS Zones

resource "azurerm_private_dns_zone" "sa_zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.aml_rg.name
}

resource "azurerm_private_dns_zone" "sa_zone_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.aml_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_blob_link" {
  name                  = "${random_string.postfix.result}_link_blob"
  resource_group_name   = azurerm_resource_group.aml_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_blob.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_file_link" {
  name                  = "${random_string.postfix.result}_link_file"
  resource_group_name   = azurerm_resource_group.aml_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_file.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "sa_pe_blob" {
  name                = "${var.prefix}-sa-pe-blob-${random_string.postfix.result}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  subnet_id           = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-sa-psc-blob-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.aml_sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "sa_pe_file" {
  name                = "${var.prefix}-sa-pe-file-${random_string.postfix.result}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  subnet_id           = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-sa-psc-file-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.aml_sa.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_file.id]
  }
}


resource "azurerm_private_endpoint" "sa_pe_blob_train" {
  name                = "${var.prefix}-satrain-pe-blob-${random_string.postfix.result}"
  location            = azurerm_resource_group.aml_rg.location
  resource_group_name = azurerm_resource_group.aml_rg.name
  subnet_id           = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-satrain-psc-blob-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.aml_train_data.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_blob.id]
  }
}

