output "cluster_name" {
  value = kind_cluster.this.name
}

output "registry" {
  value = "localhost:${var.registry_host_port}"
}

output "dev_url" {
  value = "http://app.dev.localtest.me:${var.ingress_host_port}"
}

output "prod_url" {
  value = "http://app.prod.localtest.me:${var.ingress_host_port}"
}
