resource "kubernetes_namespace_v1" "app" {
  for_each = var.app_namespaces

  metadata {
    name = each.value
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }

  depends_on = [kind_cluster.this]
}

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = "traefik"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    service = { type = "NodePort" }
    ingressClass = {
      enabled        = true
      isDefaultClass = true
      name           = "traefik"
    }
    ports = {
      web       = { nodePort = local.ingress_nodeport }
      websecure = { expose = { default = false } }
    }
  })]

  depends_on = [kind_cluster.this]
}

# Supplies the CPU metrics the HorizontalPodAutoscaler needs.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version
  namespace  = "kube-system"
  wait       = true

  # kind kubelets use self-signed certificates. Do not use this flag on a real cluster.
  values = [yamlencode({ args = ["--kubelet-insecure-tls"] })]

  depends_on = [kind_cluster.this]
}
