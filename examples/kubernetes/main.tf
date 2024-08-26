terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = ">=1.79.2"
    }
  }
}

provider "tencentcloud" {
  region = var.region
}

# It is recommended to use the vpc module to create vpc and subnets
resource "tencentcloud_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  name       = "tke-test"
}

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

resource "tencentcloud_security_group_lite_rule" "this" {
  security_group_id = tencentcloud_security_group.this.id

  ingress = [
    "ACCEPT#${var.accept_ip}#ALL#ALL",
    "DROP#0.0.0.0/0#ALL#ALL"
  ]

  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL",
  ]
}

module "tencentcloud_tke" {
  source                   = "../../"
  available_zone           = var.available_zone # Available zone must belongs to the region.
  create_cam_strategy      = false
  enhanced_monitor_service = true


  create_endpoint_with_cluster     = false # enable network access by endpoint resource
  create_workers_with_cluster      = false # create nodes by node pool resource
  cluster_public_access            = true  # enable public access
  cluster_private_access           = true  # eanble private access
  cluster_security_group_id        = tencentcloud_security_group.this.id
  node_security_group_id           = tencentcloud_security_group.this.id
  cluster_private_access_subnet_id = tencentcloud_subnet.intranet.id
  vpc_id                           = tencentcloud_vpc.this.id
  intranet_subnet_id               = tencentcloud_subnet.intranet.id


  enable_cluster_audit_log = true
  worker_bandwidth_out     = 100


  tags = {
    module = "tke"
  }

  # config standard node pool
  self_managed_node_groups = {
    test = {
      max_size                 = 4
      min_size                 = 1
      subnet_ids               = [tencentcloud_subnet.intranet.id]
      retry_policy             = "INCREMENTAL_INTERVALS"
      desired_capacity         = 2
      enable_auto_scale        = true
      multi_zone_subnet_policy = "EQUALITY"

      auto_scaling_config = [{
        instance_type              = "S5.MEDIUM2"
        system_disk_type           = "CLOUD_PREMIUM"
        system_disk_size           = 50
        orderly_security_group_ids = [tencentcloud_security_group.this.id]

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

      node_config = [{
        extra_args = ["root-dir=/var/lib/kubelet"]
      }]
    }
  }

  # config serverless node pool
  # self_managed_serverless_node_groups = {
  #   test = {
  #     name = "example_serverless_np"
  #     serverless_nodes = [{
  #       display_name = "serverless_node1"
  #       subnet_id    = tencentcloud_subnet.intranet.id
  #       },
  #       {
  #         display_name = "serverless_node2"
  #         subnet_id    = tencentcloud_subnet.intranet.id
  #       },
  #     ]
  #     security_group_ids = [tencentcloud_security_group.this.id]
  #     labels = {
  #       "example1" : "test1",
  #       "example2" : "test2",
  #     }
  #   }
  # }

}

provider "kubernetes" {
  host                   = module.tencentcloud_tke.cluster_endpoint
  cluster_ca_certificate = module.tencentcloud_tke.cluster_ca_certificate
  client_key             = base64decode(module.tencentcloud_tke.client_key)
  client_certificate     = base64decode(module.tencentcloud_tke.client_certificate)
}
