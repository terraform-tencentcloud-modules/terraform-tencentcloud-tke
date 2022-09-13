# Networks
output "vpc_id" {
  value       = tencentcloud_vpc.vpc.id
  description = "Id of VPC which created by this module."
}

output "subnet_id" {
  value       = tencentcloud_subnet.subnet.id
  description = "Id of subnet belongs to module-created VPC."
}

output "security_group_id" {
  value       = tencentcloud_security_group.sg.id
  description = "Security group id."
}

# TKEs
output "cluster_id" {
  value       = tencentcloud_kubernetes_cluster.cluster.id
  description = "TKE cluster id."
}

output "cluster_domain" {
  value       = tencentcloud_kubernetes_cluster.cluster.domain
  description = "Cluster domain."
}

output "cluster_endpoint" {
  value       = tencentcloud_kubernetes_cluster.cluster.cluster_external_endpoint
  description = "Cluster endpoint if cluster_public_access enabled"
}

output "cluster_intranet_endpoint" {
  value       = tencentcloud_kubernetes_cluster.cluster.pgw_endpoint
  description = "Cluster endpoint if cluster_private_access enabled"
}

locals {
  kube_config_raw = tencentcloud_kubernetes_cluster.cluster.kube_config
  kube_config     = yamldecode(local.kube_config_raw)
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
  value       = tencentcloud_kubernetes_cluster.cluster.kube_config_intranet
  description = "Cluster's kube config of private access."
}

output "cluster_ca_certificate" {
  value       = tencentcloud_kubernetes_cluster.cluster.certification_authority
  description = "Cluster's certification authority."
}

output "client_key" {
  value       = local.kube_config.users[0].user["client-key-data"]
  description = "Base64 encoded cluster's client pem key."
}

output "client_certificate" {
  value       = local.kube_config.users[0].user["client-certificate-data"]
  description = "Base64 encoded cluster's client pem certificate."
}