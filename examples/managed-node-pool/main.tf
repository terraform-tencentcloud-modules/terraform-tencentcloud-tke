locals {
  #  region = "ap-singapore"

  name = "test-node-pool"
  tags = {}

  vpc_cidr   = "10.0.0.0/16"
  node_cidrs = ["10.0.64.0/24", "10.0.65.0/24", "10.0.66.0/24", "10.0.67.0/24"]
  node_azs   = ["ap-singapore-1", "ap-singapore-2", "ap-singapore-3", "ap-singapore-4"]
  pod_cidrs  = ["10.0.128.0/24", "10.0.129.0/24", "10.0.130.0/24", "10.0.131.0/24"]
  pod_azs    = ["ap-singapore-1", "ap-singapore-2", "ap-singapore-3", "ap-singapore-4"]

  well-known-cidrs = [
    "0.0.0.0/0"
  ]

  docker_graph_path = "/var/lib/docker"

  node_pools = {
    default = {
      name             = "default"
      node_os          = "ubuntu20.04x86_64"
      instance_type    = "SA5.LARGE8" # "S6.LARGE8" "SA5.LARGE8"
      system_disk_type = "CLOUD_SSD"
      max_size         = 3
      min_size         = 0
      desired_capacity = 2
      retry_policy             = "IMMEDIATE_RETRY"
      multi_zone_subnet_policy = "EQUALITY"
      labels = {
        node-group : "default"
      }
      data_disks = [
        {
          disk_type : "CLOUD_SSD"
          disk_size : 100
          file_system : "ext4"
        }
      ]
      host_name           = "test-host-name"
      host_name_style     = "UNIQUE"
      instance_name       = "test-instance-name"
      instance_name_style = "UNIQUE"
    }
  }
}


module "node_network" {
  source           = "terraform-tencentcloud-modules/vpc/tencentcloud"
  version          = "1.1.0"
  vpc_name         = local.name
  vpc_cidr         = local.vpc_cidr
  vpc_is_multicast = false
  tags             = local.tags

  availability_zones = local.node_azs
  subnet_name        = "${local.name}-node"
  subnet_cidrs       = local.node_cidrs
  subnet_tags        = local.tags

  enable_nat_gateway = true
  destination_cidrs  = ["0.0.0.0/0"]
  next_type          = ["NAT"]
  next_hub           = ["0"]
}

module "pod_network" {
  source     = "terraform-tencentcloud-modules/vpc/tencentcloud"
  version    = "1.1.0"
  create_vpc = false
  vpc_id     = module.node_network.vpc_id

  availability_zones = local.pod_azs
  subnet_name        = "${local.name}-pod"
  subnet_cidrs       = local.pod_cidrs
  subnet_tags        = local.tags
}

module "sg" {
  source = "./modules/security_groups"
  security_groups = {
    well-known = {
      name = "well-known"
      ingress = [
        for cidr in local.well-known-cidrs : {
          action      = "ACCEPT"
          cidr_block  = cidr  # var.consul_private_network_source_ranges
          protocol    = "TCP" # "TCP"  # TCP, UDP and ICMP
          port        = "ALL" # "80-90" # 80, 80,90 and 80-90
          description = ""
        }
      ]
    }
  }
}

module "tke" {
  source = "../.."

  create_cam_strategy       = false
  cluster_name              = local.name
  cluster_version           = "1.28.3"
  cluster_level             = "L5"
  container_runtime         = "containerd"
  network_type              = "VPC-CNI" // Cluster network type, GR or VPC-CNI. Default is GR
  vpc_id                    = module.node_network.vpc_id
  intranet_subnet_id        = module.node_network.subnet_id[0]
  available_zone            = local.node_azs[0]
  node_security_group_id    = module.sg.ids["well-known"]
  cluster_security_group_id = module.sg.ids["well-known"]
  eni_subnet_ids            = module.pod_network.subnet_id
  cluster_service_cidr      = "192.168.128.0/17"
  cluster_max_service_num   = 32768
  cluster_max_pod_num       = 64
  cluster_cidr              = ""
  deletion_protection       = false

  # endpoints
  create_endpoint_with_cluster     = false
  cluster_public_access            = false
  cluster_private_access           = false
  cluster_private_access_subnet_id = module.node_network.subnet_id[0]

  tags = local.tags

  cluster_addons = {
    // looking for addonName here: https://console.cloud.tencent.com/api/explorer?Product=tke&Version=2018-05-25&Action=GetTkeAppChartList
    #    cfs = {},
    #    cos = {},
    #    user-group-access-control = {}, // This need whitelist
  }
  # workers
  create_workers_with_cluster = false

  self_managed_node_groups = {
    for k, node_group in local.node_pools : k => {
      name                     = try(node_group.name, k)
      max_size                 = node_group.max_size
      min_size                 = node_group.min_size
      subnet_ids               = module.node_network.subnet_id
      retry_policy             = try(node_group.retry_policy, "IMMEDIATE_RETRY")
      desired_capacity         = node_group.desired_capacity
      enable_auto_scale        = true
      multi_zone_subnet_policy = try(node_group.multi_zone_subnet_policy, "EQUALITY")
      node_os                  = node_group.node_os

      docker_graph_path = local.docker_graph_path
      data_disk = [for disk in node_group.data_disks : {
        disk_type             = try(disk.disk_type, "CLOUD_SSD")
        disk_size             = disk.disk_size # at least to configurate a disk size for data disk
        delete_with_instance  = true
        auto_format_and_mount = true
        file_system           = try(disk.file_system, "ext4")
        mount_target          = local.docker_graph_path
      }]

      auto_scaling_config = [
        {
          instance_type              = node_group.instance_type
          system_disk_type           = node_group.system_disk_type
          system_disk_size           = 50
          orderly_security_group_ids = [module.sg.ids["well-known"]]
          key_ids                    = null

          internet_charge_type       = null
          internet_max_bandwidth_out = null
          public_ip_assigned         = false
          enhanced_security_service  = true
          enhanced_monitor_service   = true
          host_name                  = try(node_group.host_name, "tke-node")
          host_name_style            = try(node_group.host_name_style, "ORIGINAL")
          instance_name              = try(node_group.instance_name, "tke-node")
          instance_name_style        = try(node_group.instance_name_style, "ORIGINAL")
        }
      ]

      labels = try(node_group.labels, {})
      taints = try(node_group.taints, [])
      node_config = [
        {
          extra_args = concat(["root-dir=/var/lib/kubelet"],
            try(node_group.extra_args, [])
          )
        }
      ]
    }
  }
}

output "tke" {
  value = module.tke
}