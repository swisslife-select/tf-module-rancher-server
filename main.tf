# Install cert-manager helm chart
resource "helm_release" "cert_manager" {
  repository = "https://charts.jetstack.io"
  name       = "jetstack"
  chart      = "cert-manager"
  version    = var.cert_manager.version
  namespace  = var.cert_manager.ns
  create_namespace = true
  wait_for_jobs = true

  dynamic set {
    for_each = var.cert_manager.chart_set
    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}

# Install Rancher helm chart
resource "helm_release" "rancher_server" {
  repository = "https://releases.rancher.com/server-charts/${var.rancher_server.branch}"
  name       = "rancher-${var.rancher_server.branch}"
  chart      = "rancher"
  version    = var.rancher_server.version
  namespace  = var.rancher_server.ns
  create_namespace = true
  wait_for_jobs = true

  set {
    name  = "hostname"
    value = var.rancher_hostname
  }

  set {
    name  = "replicas"
    value = var.rancher_replicas
  }

  dynamic set {
    for_each = var.rancher_server.chart_set
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubernetes_cluster_role" "cluster-admin" {
  metadata {
    name = "cluster-admin"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  depends_on = [
    helm_release.rancher_server
  ]
}

resource "kubernetes_cluster_role" "system-discovery" {
  metadata {
    name = "system:discovery"
  }

  rule {
    non_resource_urls = ["/api", "/api/*", "/apis", "/apis/*", "/healthz", "/livez", "/openapi", "/openapi/*", "/readyz", "/version", "/version/"]
    verbs      = ["get"]
  }

  depends_on = [
    helm_release.rancher_server
  ]
}

