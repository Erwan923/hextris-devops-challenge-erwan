output "cluster_name" {
  description = "Name of the Kind cluster"
  value       = kind_cluster.hextris.name
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = pathexpand("~/.kube/config")
}

output "ingress_ready" {
  description = "Ingress controller deployment status"
  value       = helm_release.ingress_nginx.status
}
