locals {
  node_name        = "${var.cluster_name}-control-plane"
  registry_name    = "kind-registry"
  ingress_nodeport = 30080
}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = var.node_image
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Lets containerd read per-registry settings from certs.d (see below).
    containerd_config_patches = [
      <<-TOML
      [plugins."io.containerd.grpc.v1.cri".registry]
        config_path = "/etc/containerd/certs.d"
      TOML
    ]

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = local.ingress_nodeport
        host_port      = var.ingress_host_port
        listen_address = "127.0.0.1"
        protocol       = "TCP"
      }
    }
  }
}

resource "docker_image" "registry" {
  name         = "registry:2"
  keep_locally = true
}

# Local registry on the "kind" Docker network, which kind creates with the cluster.
resource "docker_container" "registry" {
  name    = local.registry_name
  image   = docker_image.registry.image_id
  restart = "always"

  ports {
    internal = 5000
    external = var.registry_host_port
    ip       = "127.0.0.1"
  }

  networks_advanced {
    name = "kind"
  }

  depends_on = [kind_cluster.this]
}

# Tells the node to pull localhost:<port>/* images from the registry container.
resource "null_resource" "registry_mirror" {
  triggers = {
    cluster_id    = kind_cluster.this.id
    registry_port = var.registry_host_port
  }

  provisioner "local-exec" {
    command = <<-CMD
      printf '[host."http://${local.registry_name}:5000"]\n' | \
      docker exec -i ${local.node_name} sh -c '
        dir=/etc/containerd/certs.d/localhost:${var.registry_host_port}
        mkdir -p "$dir" && cat > "$dir/hosts.toml"'
    CMD
  }

  depends_on = [docker_container.registry]
}
