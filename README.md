# Terraform TencentCloud TKE Managed Cluster Module

A Terraform module which creates TencentCloud Kubernetes Engine (TKE) clusters and resource dependencies.

## Usage
### Warm-Up
Let's create a basic TKE instance with the necessary configuration, which includes security group, vpc, subnet, and region.
```hcl
provider "tencentcloud" {
  region = var.region
}

# It is recommended to use the vpc module to create vpc and subnets
resource "tencentcloud_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  name       = "tke-test"
}

# Specify the subnet of intranet
resource "tencentcloud_subnet" "intranet" {
  cidr_block        = "10.0.1.0/24"
  name              = "tke-subnet"
  availability_zone = var.available_zone
  vpc_id            = tencentcloud_vpc.this.id
}

# It is recommended to use the security group module to create security group and rules
resource "tencentcloud_security_group" "this" {
  name = "tke-security-group"
}

# Specify the ingress and egress rules for the security group
resource "tencentcloud_security_group_lite_rule" "this" {
  security_group_id = tencentcloud_security_group.this.id

  ingress = [
    "ACCEPT#${var.accept_ip}#ALL#ALL", # your ip address
    "DROP#0.0.0.0/0#ALL#ALL"
  ]

  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL",
  ]
}

# using module to create TKE resource
module "tencentcloud_tke" {
  source                   = "../../"
  available_zone           = var.available_zone # Available zone must belongs to the region.
  vpc_id                   = tencentcloud_vpc.this.id
  intranet_subnet_id       = tencentcloud_subnet.intranet.id

  # public access configuration
  cluster_public_access     = true
  cluster_security_group_id = tencentcloud_security_group.this.id

  # security group for worker nodes
  node_security_group_id    = tencentcloud_security_group.this.id

  # private access configuration
  cluster_private_access           = true
  cluster_private_access_subnet_id = tencentcloud_subnet.intranet.id

  # monitor, event audit log configuration for cluster
  enhanced_monitor_service = true
  enable_event_persistence = true
  enable_cluster_audit_log = true

  # specify the bandwidth for public access
  worker_bandwidth_out = 100

  tags = {
    module = "tke"
  }
}

# Configure Kubernetes Provider with TKE resource
provider "kubernetes" {
  host                   = module.tke.cluster_endpoint
  cluster_ca_certificate = module.tke.cluster_ca_certificate
  client_key             = base64decode(module.tke.client_key)
  client_certificate     = base64decode(module.tke.client_certificate)
}
```

### Create node pool with managed cluster:
After the warm-up process, you have obtained a managed cluster.

To conveniently create, manage, and terminate nodes and dynamically scale nodes in or out. You may want to introduce a node pool with an existing cluster. Visit [Node Pool](https://cloud.tencent.com/document/product/457/43719) for more information.

Now, let's create a node pool on this cluster.

Just add the following code block `self_managed_node_groups` into your module block.
```hcl
module "tencentcloud_tke" {
  # ...your module created in the above section...
  self_managed_node_groups = {
    test = {
      name                     = "example_np"
      max_size                 = 6
      min_size                 = 1
      subnet_ids               = [tencentcloud_subnet.intranet.id]
      retry_policy             = "INCREMENTAL_INTERVALS"
      desired_capacity         = 4
      enable_auto_scale        = true
      multi_zone_subnet_policy = "EQUALITY"

      # Specify the auto scale configuration
      auto_scaling_config = [{
        # Specify the type, disk specification for node pool
        instance_type      = "S5.MEDIUM2"
        system_disk_type   = "CLOUD_PREMIUM"
        system_disk_size   = 50
        security_group_ids = [tencentcloud_security_group.this.id]

        # Specify the data disk for the nodes of pool
        data_disk = [{
          disk_type = "CLOUD_PREMIUM"
          disk_size = 50
        }]

        internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"
        internet_max_bandwidth_out = 10
        public_ip_assigned         = true
        enhanced_security_service  = false
        enhanced_monitor_service   = false
        host_name                  = "12.123.0.0"
        host_name_style            = "ORIGINAL"
      }]

      labels = {
        "test1" = "test1",
        "test2" = "test2",
      }

      # Specify taint policy
      taints = [{
        key    = "test_taint"
        value  = "taint_value"
        effect = "PreferNoSchedule"
        },
        {
          key    = "test_taint2"
          value  = "taint_value2"
          effect = "PreferNoSchedule"
      }]

      # Specify node arguments
      node_config = [{
        extra_args = ["root-dir=/var/lib/kubelet"]
      }]
    }
  }
}

```

### Create serverless node pool with managed cluster:
Alternatively, a serverless node pool can be created with an existing cluster. This kind of node pool makes elasticity faster and more efficient. You may only care about the subnet instead of the complicated node's configuration. Visit [SuperNode Pool](https://cloud.tencent.com/document/product/457/74014) for more information.


```hcl
module "tencentcloud_tke" {
  # ...your module created in the above section...
  self_managed_serverless_node_groups = {
    test = {
      # name of the serverless node pool
      name = "example_serverless_np"
      # In this resource, we try to create two nodes in the node pool
      # Specify the first node
      serverless_nodes = [{
        display_name = "serverless_node1"
        # you only need to specify the subnet instead of the complicated node's configuration
        subnet_id    = tencentcloud_subnet.intranet.id
      },
      # Specify the Second node
      {
        display_name = "serverless_node2"
        subnet_id    = tencentcloud_subnet.intranet.id
      },
      ]
      # Specify the security group for the serverless node pool
      security_group_ids = [tencentcloud_security_group.this.id]

      # Specify labels
      labels = {
        "example1" : "test1",
        "example2" : "test2",
      }
    }
  }
}
```

## Resources
This module will be sure to create the following resource:
- 1 managed TKE Cluster.
- At least 1 CVM instance used as TKE worker node.
- Create one or more serverless node pool of TKE Cluster.

Optionally, If variable `create_cam_strategy` was set to `true` (Default), it will also create TKE related CAM role and policies and associate them:

- CAM Role `TKE_QCSRole` - to grant tke service API permission: `sts:AssumeRole`
- CAM Policy `TF_QcloudAccessForTKERoleInOpsManagement` - Provides CLS permissions for Ops management.
- CAM Policy `TF_QcloudAccessForTKERole` - Provides partial API permission of cvm, tag, clb, cls, ssl, cvm, e.g.

NOTE: 
- If you've already granted the TKE Service Permission by operating in TencentCloud Console, you won't need these resources, set `create_cam_strategy` to `false`.
- Destroy Infrastructure will also destroy `TKE_QCSRole` if enabled, you can re-create in TencentCloud Console.

## Variables

| Name                             |    Type     | Default                   | Description                                                                                                                                                      |
|:---------------------------------|:-----------:|:--------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| available_zone                   |   string    | null                      | Specify available zone of VPC subnet and TKE nodes.                                                                                                              |
| cluster_cidr                     |   string    | 172.16.0.0/22             | Cluster cidr, conflicts with its subnet.                                                                                                                         |
| cluster_name                     |   string    | example-cluster           | TKE managed cluster name.                                                                                                                                        |
| cluster_os                       |   string    | tlinux2.2(tkernel3)x86_64 | Cluster operation system image name.                                                                                                                             |
| cluster_private_access           |    bool     | false                     | Specify whether to open cluster private access.                                                                                                                  |
| cluster_private_access_subnet_id |   string    | null                      | Specify a subnet id to cluster private access.                                                                                                                   |
| cluster_public_access            |    bool     | false                     | Specify whether to open cluster public access.                                                                                                                   |
| cluster_security_group_id        |   string    | null                      | Specify custom Security Group id to cluster public access.                                                                                                       |
| cluster_version                  |   string    | 1.22.5                    | Cluster kubernetes version.                                                                                                                                      |
| create_cam_strategy              |    bool     | true                      | Specify whether to create CAM role and relative TKE essential policy. Set to false if you've enable by using TencentCloud Console.                               |
| tags                             | map(string) | {"terraform":"example"}   | Tagged for all associated resource of this module.                                                                                                               |
| vpc_id                           |   string    | null                      | Specify custom VPC id.                                                                                                                                           |
| intranet_subnet_id               |   string    | null                      | Specify a subnet id for intranet.                                                                                                                                |
| worker_count                     |   number    | 1                         | Specify node count.                                                                                                                                              |
| worker_instance_type             |   string    | S5.MEDIUM2                | Cluster node instance type.                                                                                                                                      |
| node_security_group_id           |   string    | null                      | Specify custom Security Group id to nodes.                                                                                                                       |
| worker_bandwidth_out             |   number    | null                      | Max bandwidth of Internet access in Mbps. Default is 0.                                                                                                          |
| enable_event_persistence         |    bool     | false                     | Specify weather the Event Persistence enabled.                                                                                                                   |
| event_log_set_id                 |   string    | null                      | Specify id of existing CLS log set, or auto create a new set by leave it empty.                                                                                  |
| event_log_topic_id               |   string    | null                      | Specify id of existing CLS log topic, or auto create a new topic by leave it empty.                                                                              |
| enable_cluster_audit_log         |    bool     | false                     | Specify weather the Cluster Audit enabled. NOTE: Enable Cluster Audit will also auto install Log Agent.                                                          |
| cluster_audit_log_set_id         |   string    | null                      | Specify id of existing CLS log set, or auto create a new set by leave it empty.                                                                                  |
| cluster_audit_log_topic_id       |   string    | null                      | Specify id of existing CLS log topic, or auto create a new topic by leave it empty.                                                                              |
| cluster_service_cidr             |   string    | null                      | A network address block of the service. Different from vpc cidr and cidr of other clusters within this vpc. Must be in 10./192.168/172.[16-31] segments.         |
| enhanced_monitor_service         |    bool     | false                     | To specify whether to enable cloud monitor service.                                                                                                              |
| cluster_addons                   |  map(map)   | null                      | Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`, see `tencentcloud_kubernetes_addon_attachment` |
| self_managed_node_groups         |  map(map)   | null                      | Map of self-managed node pool definitions to create. see `tencentcloud_kubernetes_node_pool`                                                                     |

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

## Authors

Created and maintained by [TencentCloud](https://github.com/terraform-tencentcloud-modules/terraform-tencentcloud-vpc)

## License

Mozilla Public License Version 2.0.
See LICENSE for full details.
