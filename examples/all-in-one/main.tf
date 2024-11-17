locals {
  region = "ap-singapore"
  short_region = "sg"
  dependency = {
    tcr_id = "tcr-xxxxxxx" // tcr.outputs.tcr_id
    tcr_name = "test-tcr-random-xxxxxx" // tcr.outputs.tcr_name
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
  vpc_id                    = "vpc-xxxxxx"
  node_security_group_id    = "sg-xxxxxx"
  eni_subnet_ids            = ["subnet-xxxxxx", "subnet-xxxxxx", "subnet-xxxxxx"]
  cluster_service_cidr      = "192.168.128.0/17"
  cluster_max_service_num   = 32768 # this number must equal to the ip number of cluster_service_cidr
  cluster_max_pod_num       = 64
  cluster_cidr              = ""
  deletion_protection       = false

  cluster_os = "tlinux2.2(tkernel3)x86_64"
  claim_expired_seconds = 300

  auto_upgrade_cluster_level = false
  is_non_static_ip_mode = false
  node_name_type = "lan-ip"
  cluster_deploy_type = "MANAGED_CLUSTER"
  cluster_desc = "test cluster"
  cluster_ipvs = true
  ignore_cluster_cidr_conflict = false
  ignore_service_cidr_conflict = false
  upgrade_instances_follow_cluster = false
  vpc_cni_type = "tke-route-eni"
  kube_proxy_mode = null

  runtime_version = "1.6.9"

  # workers
  create_workers_with_cluster = false
  node_pool_global_config = {
    is_scale_in_enabled            = true
    expander                       = "random"
    ignore_daemon_sets_utilization = true
    max_concurrent_scale_in        = 5
    scale_in_delay                 = 15
    scale_in_unneeded_time         = 15
    scale_in_utilization_threshold = 30
    skip_nodes_with_local_storage  = false
    skip_nodes_with_system_pods    = true
  }
  self_managed_node_groups = {
    node_group_1 = {
      name                     = "test-ng-1"
      deletion_protection = false
      max_size                 = 5
      min_size                 = 1
      subnet_ids               = ["subnet-xxxxxx", "subnet-xxxxxx", "subnet-xxxxxx"]
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
          orderly_security_group_ids = ["sg-xxxxxx"]
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
      host_name_pattern = "aaa{R:3}"
      deletion_protection = false
      scaling = {
        min_replicas  = 1
        max_replicas  = 5
        create_policy = "ZoneEquality"
      }
      subnet_ids           = ["subnet-xxxxxx", "subnet-xxxxxx"]
      instance_charge_type = "POSTPAID_BY_HOUR"
      system_disk = {
        disk_type = "CLOUD_SSD"
        disk_size = 50
      }
      instance_types     = ["SA2.MEDIUM8"]
      security_group_ids = ["sg-xxxxxx"]
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
      labels = [
        {
          name: "label1",
          value: "value1"
        },
        {
          name: "label2",
          value: "value2"
        }
      ]
      tags = [
        {
          resource_type = "cluster"
          tags = {
            "k1": "v1"
          }
        }
      ]

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
    native_CVM = {
      name = "test-native-cvm-pool"
      host_name_pattern = "aaa{R:3}"
      deletion_protection = false
      scaling = {
        min_replicas  = 1
        max_replicas  = 5
        create_policy = "ZoneEquality"
      }
      subnet_ids           = ["subnet-xxxxxx", "subnet-xxxxxx"]
      instance_charge_type = "POSTPAID_BY_HOUR"
      system_disk = {
        disk_type = "CLOUD_SSD"
        disk_size = 50
      }
      instance_types     = ["SA2.MEDIUM8"]
      security_group_ids = ["sg-xxxxxx"]
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
      labels = [
        {
          name: "label1",
          value: "value1"
        },
        {
          name: "label2",
          value: "value2"
        }
      ]
      tags = [
        {
          resource_type = "cluster"
          tags = {
            "k1": "v1"
          }
        }
      ]

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
        },
        {    # enabling cgroupv2
          name  = "node.tke.cloud.tencent.com/beta-image"
          value = "ts4-public"
        },
      ]
      machine_type = "NativeCVM" # enabling native CVM
    }

  }
  self_managed_serverless_node_groups = {
    sl_group1 = {
      name = "sl_group1"
      security_group_ids = ["sg-xxxxxx"]
      labels = { label1: "value1"}
      taints = [
        {
          effect = "NoSchedule"
          key = "test"
          value = "test"
        }
      ]
      serverless_nodes = [
        {
          subnet_id = "subnet-xxxxxx"
          display_name = "sl_node_1"
        }
      ]
    }
  }

  # endpoints
  create_endpoint_with_cluster     = false
  cluster_public_access             = true
  cluster_security_group_id = "sg-xxxxxx"
  cluster_private_access                = true
  cluster_private_access_subnet_id      = "subnet-xxxxxx"

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
#    user-group-access-control = {}, // This need whitelist
    oomguard = {
      legacy        = false
      addon_version = "1.0.2"
    }
    localdns = {
      legacy        = false
      addon_version = "1.0.0"
    }
    dnsautoscaler = {
      legacy        = false
      addon_version = "1.0.0"
    }
#    npdplus = {
#      legacy        = false
#      addon_version = ""
#    }
  }

  # logs
  enable_event_persistence = true
  event_log_set_id = "xxxxxx-3da2-4a4e-a68d-f3a0eb87c850"
  event_log_topic_id = "xxxxxx-5cd0-4f99-8042-bb6fc2567ef5"
  enable_cluster_audit_log = true
  cluster_audit_log_set_id = "xxxxxx-3da2-4a4e-a68d-f3a0eb87c850"
  cluster_audit_log_topic_id = "xxxxxx-5cd0-4f99-8042-bb6fc2567ef5"
  enable_log_agent = true
  log_configs = {
    cls_log_1 = {
      log_config_name = "cls-log"
      logset_id = "xxxxxx-xxxxxx"
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

  # self healing policies
  health_check_policies = {
    policy1 = {
      name = "all"
      rules = [
        {
          name                = "OOMKilling"
          auto_repair_enabled = true
          enabled             = true
        },
        {
          name                = "KubeletUnhealthy"
          auto_repair_enabled = true
          enabled             = true
        }
      ]
    }

  }


  # tags
  tags = {
    create: "terraform"
  }
  # labels
  labels = {
    "label1" = "value1",
    "label2" = "value2"
  }
}


output "all" {
  value = module.tke-all-in-one
}