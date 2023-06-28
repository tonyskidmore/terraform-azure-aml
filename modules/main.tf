terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "aks" {
  backend = "local"

  config = {
    path = "../terraform.tfstate"
  }
}

module "kubernetes-config" {
  # depends_on   = [local_file.kubeconfig]
    source             = "./aks_config"
    aks_id             = data.azurerm_kubernetes_cluster.cluster.id
    aks_name           = data.azurerm_kubernetes_cluster.cluster.name 
    aks_location       = data.azurerm_kubernetes_cluster.cluster.location
    aks_resource_group = data.azurerm_kubernetes_cluster.cluster.resource_group_name
    prefix             = data.terraform_remote_state.aks.outputs.prefix
    postfix            = data.terraform_remote_state.aks.outputs.postfix
    # aks_subnet_name    = var.aks_subnet_name
  # kubeconfig   = local_file.kubeconfig.content
    # depends_on = [
    #     data.azurerm_kubernetes_cluster.cluster
    # ]
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

# provider "kubernetes" {
#   host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

#   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
#   client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
# }
