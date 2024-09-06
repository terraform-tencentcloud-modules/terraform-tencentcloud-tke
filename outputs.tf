
# TKEs
output "cluster_id" {
  value       = local.cluster_id
  description = "TKE cluster id."
}

output "cluster_domain" {
  value       = concat(tencentcloud_kubernetes_cluster.cluster.*.domain, [""])[0]
  description = "Cluster domain."
}

output "cluster_endpoint" {
  value       = var.create_endpoint_with_cluster ? concat(tencentcloud_kubernetes_cluster.cluster.*.cluster_external_endpoint, [""])[0] : try(tencentcloud_kubernetes_cluster_endpoint.endpoints[0].cluster_external_endpoint, "")
  description = "Cluster endpoint if cluster_public_access or endpoint enabled"
}

output "cluster_intranet_endpoint" {
  value       = var.create_endpoint_with_cluster ? concat(tencentcloud_kubernetes_cluster.cluster.*.pgw_endpoint, [""])[0] : try(tencentcloud_kubernetes_cluster_endpoint.endpoints[0].pgw_endpoint, "")
  description = "Cluster endpoint if cluster_private_access or endpoint enabled"
}

locals {
  kube_config_raw = concat(tencentcloud_kubernetes_cluster.cluster.*.kube_config, [""])[0]
  kube_config     = try(yamldecode(local.kube_config_raw), "")
}

output "kube_config_raw" {
  value       = local.kube_config_raw
  description = "TKE cluster's kube config in raw."
}

output "kube_config" {
  value       = local.kube_config
  description = "YAML decoded TKE cluster's kube config."
}

output "intranet_kube_config" {
  value       = concat(tencentcloud_kubernetes_cluster.cluster.*.kube_config_intranet, [""])[0]
  description = "Cluster's kube config of private access."
}

output "cluster_ca_certificate" {
  value       = concat(tencentcloud_kubernetes_cluster.cluster.*.certification_authority, [""])[0]
  description = "Cluster's certification authority."
}

output "client_key" {
  value       = try(local.kube_config.users[0].user["client-key-data"], "")
  description = "Base64 encoded cluster's client pem key."
}

output "client_certificate" {
  value       = try(local.kube_config.users[0].user["client-certificate-data"], "")
  description = "Base64 encoded cluster's client pem certificate."
}
