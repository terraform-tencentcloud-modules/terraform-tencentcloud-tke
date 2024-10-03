locals {
  region = "ap-singapore"
  short_region = "sg"
  dependency = {
    tcr_id = "tcr-cciyge59" // tcr.outputs.tcr_id
    tcr_name = "test-tcr-random-a3gtx" // tcr.outputs.tcr_name
    user_name = "2000000000" // tcr.outputs.user_name
    token = "xx.xx.xx-xx-xx-xx" // tcr.outputs.token
    internal_ip = "10.0.2.7" // tcr.output.access_ips[0]
  }
}

module "tke-all-in-one" {
  source = "../.."

  create_cam_strategy = false
  create_cluster = true

  # cluster
  cluster_name              = "test-tke-cluster"
  cluster_version           = "1.28.3"
  cluster_level             = "L5"
  container_runtime         = "containerd"
  network_type              = "VPC-CNI" // Cluster network type, GR or VPC-CNI. Default is GR
  vpc_id                    = "vpc-j0sqtqk7"
  intranet_subnet_id        = ""
  available_zone            = ""
  node_security_group_id    = "sg-00phmnm8"
  eni_subnet_ids            = ["subnet-0qoq4mg0", "subnet-p6xvdq6i", "subnet-djxwglcy"]
  cluster_service_cidr      = "192.168.128.0/17"
  cluster_max_service_num   = 32768 # this number must equal to the ip number of cluster_service_cidr
  cluster_max_pod_num       = 64
  cluster_cidr              = ""
  deletion_protection       = false

  # workers
  create_workers_with_cluster = false
  self_managed_node_groups = {
    node_group_1 = {
      name                     = "test-ng-1"
      max_size                 = 5
      min_size                 = 1
      subnet_ids               = ["subnet-0qoq4mg0", "subnet-p6xvdq6i", "subnet-djxwglcy"]
      retry_policy             = "IMMEDIATE_RETRY"
      desired_capacity         = 3
      enable_auto_scale        = true
      multi_zone_subnet_policy = "EQUALITY"
      node_os                  = "ubuntu20.04x86_64"

      docker_graph_path = "/var/lib/docker"
      data_disk = [
        {
          disk_type = "CLOUD_SSD"
          disk_size = 100 # at least to configurate a disk size for data disk
          delete_with_instance = true
          auto_format_and_mount = true
          file_system = "ext4"
          mount_target = "/var/lib/docker"
        }
      ]

      auto_scaling_config = [
        {
          instance_type              = "SA5.LARGE8"
          system_disk_type           = "CLOUD_SSD"
          system_disk_size           = 50
          orderly_security_group_ids = ["sg-00phmnm8"]
          key_ids                    = null

          internet_charge_type       = null
          internet_max_bandwidth_out = null
          public_ip_assigned         = false
          enhanced_security_service  = true
          enhanced_monitor_service   = true
          host_name                  = "tke-node"
          host_name_style            = "ORIGINAL"
        }
      ]

      labels      = {}
      taints      = []
      node_config = [
        {
          extra_args = concat(["root-dir=/var/lib/kubelet"],
            []
          )
        }
      ]
    }
  }
  native_node_pools = {
    native_1 = {
      name = "test-native-pool"
      scaling = {
        min_replicas  = 1
        max_replicas  = 5
        create_policy = "ZoneEquality"
      }
      subnet_ids           = ["subnet-p6xvdq6i", "subnet-djxwglcy"]
      instance_charge_type = "POSTPAID_BY_HOUR"
      system_disk = {
        disk_type = "CLOUD_SSD"
        disk_size = 50
      }
      instance_types     = ["SA2.MEDIUM8"]
      security_group_ids = ["sg-00phmnm8"]
      auto_repair        = true
      lifecycle = {
        pre_init  = "ZWNobyBoZWxsb3dvcmxk"
        post_init = "ZWNobyBoZWxsb3dvcmxk"
      }
      runtime_root_dir   = "/var/lib/docker"
      enable_autoscaling = true

      replicas = 2

      internet_accessible = {
        max_bandwidth_out = 50
        charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"
      }
      data_disks = [
        {
          disk_type             = "CLOUD_PREMIUM"
          file_system           = "ext4"
          disk_size             = 60
          mount_target          = "/var/lib/docker"
          auto_format_and_mount = true
        }
      ]
      labels = {
        label1 : "value1",
        label2 : "value2"
      }

      taints = [
        {
          key    = "product"
          value  = "coderider"
          effect = "NoExecute"
        },
        {
          key    = "dev"
          value  = "coderider"
          effect = "NoExecute"
        }
      ]

      annotations = [
        {
          name  = "node.tke.cloud.tencent.com/test-anno"
          value = "test"
        },
        {
          name  = "node.tke.cloud.tencent.com/test-label"
          value = "test"
        }
      ]
    }

  }

  # endpoints
  create_endpoint_with_cluster     = false
  cluster_public_access             = true
  cluster_security_group_id = "sg-00phmnm8"
  cluster_private_access                = true
  cluster_private_access_subnet_id      = "subnet-0qoq4mg0"

  tags = {
    create: "terraform"
  }

  # addons
  cluster_addons = {
    cfs = {
      legacy        = false
      addon_version = "1.1.6"
    },
    cos = {
      legacy        = false
      addon_version = "1.0.6"
    },
    tcr = {
      legacy        = false
      addon_version = "1.0.2"
      raw_values    = {
        global = {
          imagePullSecretsCrs = [
            {
              name            = "${local.dependency.tcr_id}-vpc"
              namespaces      = "*"
              serviceAccounts = "*"
              type            = "docker"
              dockerUsername  = local.dependency.user_name
              dockerPassword  = local.dependency.token
              dockerServer    = "${local.dependency.tcr_name}-vpc.tencentcloudcr.com"
            },
            {
              name            = "${local.dependency.tcr_id}-public"
              namespaces      = "*"
              serviceAccounts = "*"
              type            = "docker"
              dockerUsername  = local.dependency.user_name
              dockerPassword  = local.dependency.token
              dockerServer    = "${local.dependency.tcr_name}.tencentcloudcr.com"
            }
          ]
          cluster = {
            region     = local.short_region
            longregion = local.region
          }
          hosts = [
            {
              domain   = "${local.dependency.tcr_name}-vpc.tencentcloudcr.com"
              ip       = local.dependency.internal_ip
              disabled = false
            },
            {
              domain   = "${local.dependency.tcr_name}.tencentcloudcr.com"
              ip       = local.dependency.internal_ip
              disabled = false
            }
          ]
        }
      }
    }
  }

  # logs
  enable_event_persistence = true
  enable_cluster_audit_log = true
  enable_log_agent = true
  log_configs = {
    cls_log_1 = {
      log_config_name = "cls-log"
      logset_id = "zu6wv6-1258685193"
      spec = {
        "clsDetail" : {
          "extractRule" : {
            "backtracking" : "0",
            "isGBK" : "false",
            "jsonStandard" : "false",
            "unMatchUpload" : "false"
          },
          "indexs" : [
            {
              "indexName" : "namespace"
            },
            {
              "indexName" : "pod_name"
            },
            {
              "indexName" : "container_name"
            }
          ],
          "logFormat" : "default",
          "logType" : "minimalist_log",
          "maxSplitPartitions" : 0,
          "region" : "ap-singapore",
          "storageType" : "",
          #   "topicId" : "c26b66bd-617e-4923-bea0-test"
        },
        "inputDetail" : {
          "containerStdout" : {
            "metadataContainer" : [
              "namespace",
              "pod_name",
              "pod_ip",
              "pod_uid",
              "container_id",
              "container_name",
              "image_name",
              "cluster_id"
            ],
            "nsLabelSelector" : "",
            "workloads" : [
              {
                "kind" : "deployment",
                "name" : "testlog1",
                "namespace" : "default"
              }
            ]
          },
          "type" : "container_stdout"
        }
      }
    }
  }

  # pod identity
  enable_pod_identity = true

}

output "all" {
  value = module.tke-all-in-one
}