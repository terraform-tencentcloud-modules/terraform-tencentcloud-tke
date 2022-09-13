# Terraform TencentCloud TKE Managed Cluster Module

A Terraform module which creates TencentCloud Kubernetes Engine (TKE) clusters and resource dependencies.

## Usage

```hcl
variable "my_ip_address" {
  default = "123.123.123.123" # Specify your ip address or 0.0.0.0
}

module "tke" {
  source = "terraform-tencentcloud-modules/tke/tencentcloud"
  available_zone = "ap-hongkong-2" # Available zone must belongs to the region.
  security_ingress_rules = [
    "ACCEPT#10.0.0.0/16#ALL#ALL",
    "ACCEPT#172.16.0.0/22#ALL#ALL",
    "ACCEPT#${var.my_ip_address}#ALL#ALL",
    "DROP#0.0.0.0/0#ALL#ALL"
  ]
}

# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = module.tke.cluster_endpoint
  cluster_ca_certificate = module.tke.cluster_ca_certificate
  client_key             = base64decode(module.tke.client_key)
  client_certificate     = base64decode(module.tke.client_certificate)
}
```

## Resources
This module will be sure to create the following resource:

- 1 Virtual Private Cloud (VPC) network.
- 1 Subnet of VPC.
- 1 Security Group.
- 1 managed TKE Cluster.
- At least 1 CVM instance used as TKE worker node.

Optionally, If variable `create_cam_strategy` was set to `true` (Default), it will also create TKE related CAM role and policies and associate them:

- CAM Role `TF_TKE_QCSRole` - to grant tke service API permission: `sts:AssumeRole`
- CAM Policy `TF_QcloudAccessForTKERoleInOpsManagement` - Provides CLS permissions for Ops management.
- CAM Policy `TF_QcloudAccessForTKERole` - Provides partial API permission of cvm, tag, clb, cls, ssl, cvm, e.g.

NOTE: If you've already granted the TKE Service Permission by operating in TencentCloud Console, you won't need these resources, set `create_cam_strategy` to `false`.


## Variables

|Name|Type|Default|Description|
|:---:|:---:|:---:|:---|
|available_zone|string|ap-guangzhou-3|Specify available zone of VPC subnet and TKE nodes.|
|cluster_cidr|string|172.16.0.0/22|Cluster cidr, conflicts with its subnet.|
|cluster_name|string|example-cluster|TKE managed cluster name.|
|cluster_os|string|tlinux2.2(tkernel3)x86_64|Cluster operation system image name.|
|cluster_private_access|bool|true|Specify whether to open cluster private access.|
|cluster_public_access|bool|true|Specify whether to open cluster public access.|
|cluster_version|string|1.22.5|Cluster kubernetes version.|
|create_cam_strategy|bool|true|Specify whether to create CAM role and relative TKE essential policy. Set to false if you've enable by using TencentCloud Console.|
|network_cidr|string|10.0.0.0/16|Specify VPC and subnet CIDR.|
|security_group_name|string|example-security-group|Specify custom Security Group Name.|
|security_ingress_rules|list(string)|ACCEPT#10.0.0.0/16#ALL#ALL, ACCEPT#172.16.0.0/22#ALL#ALL, DROP#0.0.0.0/0#ALL#ALL|Specify public access policy. You can optionally use simple ["ACCEPT#0.0.0.0/0#ALL#ALL"] to allow all public access (not recommended).|
|subnet_name|string|example-subnet|Specify custom Subnet Name.|
|tags|map(string)|{"terraform":"example"}|Tagged for all associated resource of this module.|
|vpc_name|string|example-vpc|Specify custom VPC Name.|
|worker_count|number|1|Specify node count.|
|worker_instance_type|string|S5.MEDIUM2|Cluster node instance type.|

## Outputs
|Name|Description|
|:---:|:---|
|client_certificate|Base64 encoded cluster's client pem certificate.|
|client_key|Base64 encoded cluster's client pem key.|
|cluster_ca_certificate|Cluster's certification authority.|
|cluster_domain|Cluster domain.|
|cluster_endpoint|Cluster endpoint if cluster_public_access enabled|
|cluster_id|TKE cluster id.|
|cluster_intranet_endpoint|Cluster endpoint if cluster_private_access enabled|
|intranet_kube_config|Cluster's kube config of private access.|
|kube_config|YAML decoded TKE cluster's kube config.|
|kube_config_raw|TKE cluster's kube config in raw.|
|security_group_id|Security group id.|
|subnet_id|Id of subnet belongs to module-created VPC.|
|vpc_id|Id of VPC which created by this module.|


## Authors

Created and maintained by [TencentCloud](https://github.com/terraform-tencentcloud-modules/terraform-tencentcloud-vpc)

## License

Mozilla Public License Version 2.0.
See LICENSE for full details.
