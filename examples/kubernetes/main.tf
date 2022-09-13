terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = ">=1.77.7"
    }
  }
}

provider "tencentcloud" {
  region = var.region
}

module "tencentcloud_tke" {
  source         = "../../"
  available_zone = var.available_zone # Available zone must belongs to the region.
  security_ingress_rules = [
    "ACCEPT#10.0.0.0/16#ALL#ALL",
    "ACCEPT#172.16.0.0/22#ALL#ALL",
    "ACCEPT#${var.accept_ip}#ALL#ALL",
    "DROP#0.0.0.0/0#ALL#ALL"
  ]
}

provider "kubernetes" {
  host                   = module.tencentcloud_tke.cluster_endpoint
  cluster_ca_certificate = module.tencentcloud_tke.cluster_ca_certificate
  client_key             = base64decode(module.tencentcloud_tke.client_key)
  client_certificate     = base64decode(module.tencentcloud_tke.client_certificate)
}