variable "cluster_name" {
  description = "Name of the kind cluster."
  type        = string
  default     = "devops-lab"
}

variable "node_image" {
  description = "Kubernetes node image used by kind."
  type        = string
  default     = "kindest/node:v1.33.1"
}

variable "ingress_host_port" {
  description = "Port on your computer that forwards to the ingress controller."
  type        = number
  default     = 8088
}

variable "registry_host_port" {
  description = "Port on your computer for the local image registry. 5000 is avoided because macOS AirPlay uses it."
  type        = number
  default     = 5001
}

variable "app_namespaces" {
  description = "Namespaces the pipeline deploys to."
  type        = set(string)
  default     = ["demo-dev", "demo-prod"]
}

variable "traefik_chart_version" {
  description = "Traefik Helm chart version."
  type        = string
  default     = "34.4.1"
}

variable "metrics_server_chart_version" {
  description = "metrics-server Helm chart version."
  type        = string
  default     = "3.12.2"
}
