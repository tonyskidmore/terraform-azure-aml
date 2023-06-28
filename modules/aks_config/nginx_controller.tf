resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "ingress"
  }
}

# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.4.2"
  namespace  = kubernetes_namespace.nginx_ingress.metadata.0.name

  set {
    name  = "controller.service.externalTrafficPolicy" #https://github.com/Azure/AKS/issues/2903
    value = "Local"
    type  = "string"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
    value = "true"
    type  = "string"
  }
    set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal-subnet"
    value = "${var.prefix}-aks-subnet-${var.postfix}"
    type  = "string"
  }

  # "${var.prefix}-aks-subnet-${var.postfix}"

#   depends_on = [
#     data.azurerm_kubernetes_cluster.default
#   ]
}

# resource "local_file" "kubeconfig" {
#   content  = var.kubeconfig
#   filename = "${path.root}/kubeconfig"
# }
