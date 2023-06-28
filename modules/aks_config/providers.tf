terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.41.0"
    }
    azapi = {
      source  = "azure/azapi"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.17.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
}

# provider "azurerm" {
#   features {}
# }

# provider "kubernetes" {
#   config_path    = "${path.root}/kubeconfig"
#   config_context = "aks-privateaml"
# }

# provider "kubernetes" {
#   host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
#   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
#   client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
# }
