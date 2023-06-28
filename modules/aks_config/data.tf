# data "azurerm_kubernetes_cluster" "default" {
#   # depends_on          = [module.aks-cluster] # refresh cluster state before reading
#   name                = var.aks_name
#   resource_group_name = var.aks_resource_group
# }