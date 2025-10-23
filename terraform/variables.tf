variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "hextris-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for Kind cluster"
  type        = string
  default     = "v1.27.3"
}

variable "ingress_nginx_version" {
  description = "Version of nginx ingress controller"
  type        = string
  default     = "4.8.3"
}
