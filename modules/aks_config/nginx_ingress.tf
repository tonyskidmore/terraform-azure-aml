resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "azureml-fe"
    namespace= "azureml"
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/aml/"
          path_type = "Prefix"
          backend {
            service {
                name = "azureml-fe"
                port {
                    number = 80
                }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.nginx_ingress,
    azurerm_kubernetes_cluster_extension.machine_learning
        # azapi_resource.mlextension
  ]
}