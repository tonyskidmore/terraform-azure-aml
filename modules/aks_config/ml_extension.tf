# https://github.com/Azure/AML-Kubernetes/blob/master/files/terraform-template.tf
# https://github.com/Azure/AML-Kubernetes/blob/master/docs/deploy-extension.md#review-azureml-deployment-configuration-settings
# https://github.com/Azure/AML-Kubernetes/issues/285
# https://github.com/Azure/AML-Kubernetes/issues/284


# resource "azapi_resource" "mlextension" {
#   type = "Microsoft.KubernetesConfiguration/extensions@2022-11-01"
#   name = "aksextml"
#   parent_id = var.aks_id
#   identity {
#     type = "SystemAssigned"
#   }
#   body = jsonencode({
#     properties = {
#       autoUpgradeMinorVersion = true
#       configurationProtectedSettings = {}
#       configurationSettings = {
#             allowInsecureConnections="true"
#             clusterId= var.aks_id
#             clusterPurpose= "DevTest"
#             cluster_name= var.aks_name
#             cluster_name_friendly= var.aks_name
#             enableTraining="true"
#             enableInference= "true"
#             inferenceRouterHA= "true"
#             inferenceRouterServiceType= "ClusterIP"
#             //internalLoadBalancerProvider="azure"
#             jobSchedulerLocation= var.aks_location
#             location=var.aks_location
#             domain= var.aks_location
#             "prometheus.prometheusSpec.externalLabels.cluster.name"= var.aks_id
#             //"nginxIngress.enabled"= "false"
#             "relayserver.enabled"= "false"
#             "servicebus.enabled"= "false"
#             installNvidiaDevicePlugin= "false"
#             installPromOp="true"
#             installVolcano="true"
#             installDcgmExporter="false"    
#       }
#       extensionType = "microsoft.azureml.kubernetes"
#       releaseTrain = "stable"
#       scope = {
#         cluster = {
#           releaseNamespace = "azureml"
#         }
#       }
#     }
#   })

#   timeouts {
#     create = "60m"
#     delete = "60m"
#   }

#   depends_on = [
#     helm_release.nginx_ingress
#   ]
# }

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group
}

# data "azurerm_key_vault_certificate_data" "certificate" {
#   key_vault_id = "{key-vault-id}"
#   name         = "{certificate-name}"
# }

# Deploy Azure Machine Learning extension on AKS or Arc Kubernetes cluster
# https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-kubernetes-extension?view=azureml-api-2&tabs=deploy-extension-with-cli

resource "azurerm_kubernetes_cluster_extension" "machine_learning" {
  # name           = "{extension-name}"
  name           = "aksextml"
  cluster_id     = data.azurerm_kubernetes_cluster.aks.id
  extension_type = "Microsoft.AzureML.Kubernetes"

  release_namespace = "azureml" # Fixed value, do not change

  configuration_settings = {
    enableTraining                                          = true
    enableInference                                         = true
    inferenceRouterServiceType                              = "loadBalancer"
    allowInsecureConnections                                = true
    "scoringFe.serviceType.internalLoadBalancer"            = true
    privateEndpointILB                                      = true
    # sslCname                                                = "{endpoint.contoso.com}"
    "servicebus.enabled"                                    = false
    "relayserver.enabled"                                   = false
    "nginxIngress.enabled"                                  = true
    cluster_name                                            = data.azurerm_kubernetes_cluster.aks.id
    domain                                                  = "${data.azurerm_kubernetes_cluster.aks.location}.cloudapp.azure.com"
    location                                                = data.azurerm_kubernetes_cluster.aks.location
    jobSchedulerLocation                                    = data.azurerm_kubernetes_cluster.aks.location
    cluster_name_friendly                                   = data.azurerm_kubernetes_cluster.aks.name
    clusterId                                               = data.azurerm_kubernetes_cluster.aks.id
    "prometheus.prometheusSpec.externalLabels.cluster_name" = data.azurerm_kubernetes_cluster.aks.id
  }
#   configuration_protected_settings = {
#     "scoringFe.sslKey"  = base64encode(data.azurerm_key_vault_certificate_data.certificate.key)
#     "scoringFe.sslCert" = base64encode(data.azurerm_key_vault_certificate_data.certificate.pem)
#   }

  timeouts {
    create = "60m"
    delete = "60m"
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}