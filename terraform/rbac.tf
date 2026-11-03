# Jenkins gets a dedicated identity limited to the app namespaces, not cluster-admin.
resource "kubernetes_namespace_v1" "ci" {
  metadata {
    name = "ci"
  }

  depends_on = [kind_cluster.this]
}

resource "kubernetes_service_account_v1" "jenkins" {
  metadata {
    name      = "jenkins-deployer"
    namespace = kubernetes_namespace_v1.ci.metadata[0].name
  }
}

resource "kubernetes_secret_v1" "jenkins_token" {
  metadata {
    name      = "jenkins-deployer-token"
    namespace = kubernetes_namespace_v1.ci.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.jenkins.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "kubernetes_role_v1" "deployer" {
  for_each = kubernetes_namespace_v1.app

  metadata {
    name      = "deployer"
    namespace = each.value.metadata[0].name
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding_v1" "deployer" {
  for_each = kubernetes_role_v1.deployer

  metadata {
    name      = "jenkins-deployer"
    namespace = each.value.metadata[0].namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = each.value.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.jenkins.metadata[0].name
    namespace = kubernetes_namespace_v1.ci.metadata[0].name
  }
}

# Jenkins runs on the kind Docker network, so it uses the node's internal address.
resource "local_sensitive_file" "jenkins_kubeconfig" {
  filename        = "${path.module}/../jenkins/generated/kubeconfig"
  file_permission = "0600"

  content = templatefile("${path.module}/templates/kubeconfig.tftpl", {
    server  = "https://${local.node_name}:6443"
    ca_data = base64encode(kind_cluster.this.cluster_ca_certificate)
    token   = kubernetes_secret_v1.jenkins_token.data["token"]
  })
}
