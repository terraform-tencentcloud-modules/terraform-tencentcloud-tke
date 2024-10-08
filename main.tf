resource "random_password" "worker_pwd" {
  length           = 12
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "tencentcloud_kubernetes_cluster" "cluster" {
  count                           = var.create_cluster ? 1 : 0
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_cidr                    = var.cluster_cidr
  cluster_os                      = var.cluster_os
  container_runtime               = var.container_runtime
  cluster_level                   = var.cluster_level
  cluster_max_pod_num             = var.cluster_max_pod_num
  cluster_internet                = var.create_endpoint_with_cluster ? var.cluster_public_access : false
  cluster_internet_security_group = var.create_endpoint_with_cluster ? (var.cluster_public_access ? var.cluster_security_group_id : null) : null
  cluster_intranet                = var.create_endpoint_with_cluster ? var.cluster_private_access : false
  cluster_intranet_subnet_id      = var.create_endpoint_with_cluster ? (var.cluster_private_access ? local.cluster_private_access_subnet_id : null) : null
  vpc_id                          = var.vpc_id
  service_cidr                    = var.cluster_service_cidr
  network_type                    = var.network_type
  eni_subnet_ids                  = var.eni_subnet_ids
  claim_expired_seconds           = var.claim_expired_seconds
  cluster_max_service_num         = var.cluster_max_service_num
  deletion_protection             = var.deletion_protection

  auto_upgrade_cluster_level = var.auto_upgrade_cluster_level
  is_non_static_ip_mode = var.is_non_static_ip_mode
  node_name_type = var.node_name_type
  cluster_deploy_type = var.cluster_deploy_type
  cluster_desc = var.cluster_desc
  cluster_ipvs = var.cluster_ipvs
  ignore_cluster_cidr_conflict = var.ignore_cluster_cidr_conflict
  ignore_service_cidr_conflict = var.network_type == "VPC-CNI" ? var.ignore_service_cidr_conflict : null
  upgrade_instances_follow_cluster = var.upgrade_instances_follow_cluster
  vpc_cni_type = var.vpc_cni_type
  kube_proxy_mode = var.kube_proxy_mode

  dynamic "worker_config" {
    for_each = var.create_workers_with_cluster == true ? [1] : []
    content {
      availability_zone          = var.available_zone
      count                      = var.worker_count
      instance_type              = var.worker_instance_type
      subnet_id                  = var.intranet_subnet_id
      security_group_ids         = [var.node_security_group_id]
      enhanced_monitor_service   = var.enhanced_monitor_service
      public_ip_assigned         = true
      internet_max_bandwidth_out = var.worker_bandwidth_out
      # check the internal message on your account message center if needed
      password = random_password.worker_pwd.result
    }
  }

  dynamic "node_pool_global_config" {
    for_each = var.node_pool_global_config == null ? [] : [1]
    content {
      is_scale_in_enabled            = try(var.node_pool_global_config.is_scale_in_enabled ,true)
      expander                       = try(var.node_pool_global_config.expander ,"random")
      ignore_daemon_sets_utilization = try(var.node_pool_global_config.ignore_daemon_sets_utilization ,true)
      max_concurrent_scale_in        = try(var.node_pool_global_config.max_concurrent_scale_in ,5)
      scale_in_delay                 = try(var.node_pool_global_config.scale_in_delay ,15)
      scale_in_unneeded_time         = try(var.node_pool_global_config.scale_in_unneeded_time ,15)
      scale_in_utilization_threshold = try(var.node_pool_global_config.scale_in_utilization_threshold ,30)
      skip_nodes_with_local_storage  = try(var.node_pool_global_config.skip_nodes_with_local_storage ,false)
      skip_nodes_with_system_pods    = try(var.node_pool_global_config.skip_nodes_with_system_pods ,true)
    }
  }

  log_agent {
    enabled          = var.enable_log_agent
    kubelet_root_dir = var.kubelet_root_dir // optional
  }

  event_persistence {
    enabled                    = var.enable_event_persistence
    delete_event_log_and_topic = var.event_log_topic_id == null
    log_set_id                 = var.event_log_set_id
    topic_id                   = var.event_log_topic_id
  }

  cluster_audit {
    enabled                    = var.enable_cluster_audit_log
    delete_audit_log_and_topic = var.cluster_audit_log_topic_id == null
    log_set_id                 = var.cluster_audit_log_set_id
    topic_id                   = var.cluster_audit_log_topic_id
  }

  tags = var.tags
  labels = var.labels

  lifecycle {
    ignore_changes = [ // leave control to tencentcloud_kubernetes_cluster_endpoint
      cluster_intranet,
      cluster_intranet_subnet_id,
      cluster_internet,
      cluster_internet_security_group,
      kube_config,         // computed
      kube_config_intranet // computed
    ]
  }
}

locals {
  // to enable new style addons, set addon.legacy to `false`, see `examples/new-addons`
  cluster_addons        = { for k, addon in var.cluster_addons : k => addon if try(addon.installed, true) && !try(addon.legacy, true) }
  cluster_legacy_addons = { for k, addon in var.cluster_addons : k => addon if try(addon.installed, true) && try(addon.legacy, true) }

  cluster_private_access_subnet_id = var.cluster_private_access_subnet_id
  cluster_id                       = var.create_cluster ? concat(tencentcloud_kubernetes_cluster.cluster.*.id, [""])[0] : var.cluster_id
}

resource "tencentcloud_kubernetes_addon_attachment" "this" {
  # This resource will be deprecated, instead by `tencentcloud_kubernetes_addon`
  for_each = local.cluster_legacy_addons

  cluster_id = local.cluster_id
  name       = try(each.value.name, each.key)

  version      = try(each.value.version, null)
  values       = try(each.value.values, null)
  request_body = try(each.value.request_body, null)


  depends_on = [
    tencentcloud_kubernetes_node_pool.this
  ]
}

resource "tencentcloud_kubernetes_addon" "addons" {
  for_each = local.cluster_addons

  cluster_id    = local.cluster_id
  addon_name    = try(each.value.addon_name, each.key)
  addon_version = try(each.value.addon_version, null)
  raw_values    = try(each.value.raw_values, "") == "" ? "" : jsonencode(each.value.raw_values)

  depends_on = [
    tencentcloud_kubernetes_node_pool.this
  ]
}

resource "tencentcloud_kubernetes_node_pool" "this" {
  for_each                 = var.self_managed_node_groups
  name                     = try(each.value.name, each.key)
  cluster_id               = local.cluster_id
  max_size                 = try(each.value.max_size, each.value.min_size, 1)
  min_size                 = try(each.value.min_size, each.value.max_size, 1)
  vpc_id                   = var.vpc_id
  subnet_ids               = try(each.value.subnet_ids, [var.intranet_subnet_id])
  retry_policy             = try(each.value.retry_policy, "IMMEDIATE_RETRY")
  desired_capacity         = try(each.value.desired_capacity, null)
  enable_auto_scale        = try(each.value.enable_auto_scale, true)
  multi_zone_subnet_policy = try(each.value.multi_zone_subnet_policy, "EQUALITY")
  node_os                  = try(each.value.node_os, var.cluster_os)
  delete_keep_instance     = try(each.value.delete_keep_instance, false)
  deletion_protection      = try(each.value.deletion_protection, false)

  dynamic "auto_scaling_config" {
    for_each = try(each.value.auto_scaling_config, {})
    content {
      instance_type              = try(auto_scaling_config.value.instance_type, var.worker_instance_type, null)
      backup_instance_types      = try(auto_scaling_config.value.backup_instance_types, null)
      system_disk_type           = try(auto_scaling_config.value.system_disk_type, "CLOUD_PREMIUM")
      system_disk_size           = try(auto_scaling_config.value.system_disk_size, 50)
      orderly_security_group_ids = try(auto_scaling_config.value.orderly_security_group_ids, null)
      key_ids                    = try(auto_scaling_config.value.key_ids, null)

      public_ip_assigned         = try(auto_scaling_config.value.public_ip_assigned, false)
      internet_charge_type       = try(auto_scaling_config.value.internet_charge_type, null)       #"TRAFFIC_POSTPAID_BY_HOUR")
      internet_max_bandwidth_out = try(auto_scaling_config.value.internet_max_bandwidth_out, null) # 10)
      bandwidth_package_id       = try(auto_scaling_config.value.bandwidth_package_id, null)
      spot_instance_type         = try(auto_scaling_config.value.spot_instance_type, null)
      spot_max_price             = try(auto_scaling_config.value.spot_max_price, null)

      instance_charge_type                    = try(auto_scaling_config.value.instance_charge_type, null)
      instance_charge_type_prepaid_period     = try(auto_scaling_config.value.instance_charge_type_prepaid_period, null)
      instance_charge_type_prepaid_renew_flag = try(auto_scaling_config.value.instance_charge_type_prepaid_renew_flag, null)

      cam_role_name = try(auto_scaling_config.value.cam_role_name, null)

      password                  = try(auto_scaling_config.value.password, random_password.worker_pwd.result, null)
      enhanced_security_service = try(auto_scaling_config.value.enhanced_security_service, true)
      enhanced_monitor_service  = try(auto_scaling_config.value.enhanced_monitor_service, true)
      host_name                 = try(auto_scaling_config.value.host_name, null)
      host_name_style           = try(auto_scaling_config.value.host_name_style, null)
      instance_name             = try(auto_scaling_config.value.instance_name, null)
      instance_name_style       = try(auto_scaling_config.value.instance_name_style, null)

      dynamic "data_disk" {
        for_each = try(each.value.data_disk, [])
        content {
          disk_type            = try(data_disk.value.disk_type, "CLOUD_PREMIUM")
          disk_size            = try(data_disk.value.disk_size, 50)
          delete_with_instance = try(data_disk.value.delete_with_instance, false)
        }
      }
    }
  }

  labels = try(each.value.labels, null)
  tags   = merge(var.tags, try(each.value.tags, {}))

  dynamic "taints" {
    for_each = try(each.value.taints, {})
    content {
      key    = try(taints.value.key, null)
      value  = try(taints.value.value, null)
      effect = try(taints.value.effect, null)
    }
  }

  dynamic "node_config" {
    for_each = try(each.value.node_config, null)
    content {
      dynamic "data_disk" {
        for_each = try(each.value.data_disk, [])
        content {
          disk_type             = try(data_disk.value.disk_type, "CLOUD_PREMIUM")
          disk_size             = try(data_disk.value.disk_size, 50)
          auto_format_and_mount = try(data_disk.value.auto_format_and_mount, true)
          file_system           = try(data_disk.value.file_system, "xfs")
          mount_target          = try(each.value.docker_graph_path, "/var/lib/containerd")
        }
      }
      docker_graph_path = try(each.value.docker_graph_path, "/var/lib/containerd")
      extra_args        = try(node_config.value.extra_args, null)
    }
  }
  lifecycle {
    ignore_changes = [
      desired_capacity // desired_capacity should be controlled by auto scaling
    ]
  }
}

resource "tencentcloud_kubernetes_serverless_node_pool" "this" {
  for_each   = var.self_managed_serverless_node_groups
  name       = try(each.value.name, each.key)
  cluster_id = local.cluster_id
  dynamic "serverless_nodes" {
    for_each = try(each.value.serverless_nodes, [])
    content {
      display_name = try(serverless_nodes.value.display_name, null)
      subnet_id    = try(serverless_nodes.value.subnet_id, null)
    }
  }
  security_group_ids = try(each.value.security_group_ids, null)
  labels             = try(each.value.labels, null)
  dynamic "taints" {
    for_each = try(each.value.taints, [])
    content {
      effect = taints.value.effect
      key = taints.value.key
      value = taints.value.value
    }
  }
}

resource "tencentcloud_kubernetes_cluster_endpoint" "endpoints" {
  count                           = !var.create_endpoint_with_cluster && (var.cluster_public_access || var.cluster_private_access) ? 1 : 0
  cluster_id                      = local.cluster_id
  cluster_internet                = var.cluster_public_access
  cluster_internet_domain         = var.cluster_internet_domain
  cluster_internet_security_group = var.cluster_public_access ? var.cluster_security_group_id : null
  cluster_intranet                = var.cluster_private_access
  cluster_intranet_domain         = var.cluster_intranet_domain
  cluster_intranet_subnet_id      = var.cluster_private_access ? local.cluster_private_access_subnet_id : null
  depends_on = [
    tencentcloud_kubernetes_node_pool.this,
    tencentcloud_kubernetes_serverless_node_pool.this,
    tencentcloud_kubernetes_native_node_pool.native_node_pools
  ]
}


resource "tencentcloud_kubernetes_native_node_pool" "native_node_pools" {
  for_each = var.native_node_pools
  name       = try(each.value.name, each.key)
  cluster_id = local.cluster_id
  type       = try(each.value.type, "Native") # Native only

  dynamic "labels" {
    for_each = each.value.labels
    content {
      name  = labels.key
      value = labels.value
    }
  }

  dynamic "taints" {
    for_each = each.value.taints
    content {
      key    = taints.value.key // "product"
      value  = taints.value.value //"coderider"
      effect = taints.value.effect // "NoExecute"
    }
  }

  dynamic "tags" {
    for_each = try(each.value.tags, [])
    content {
      resource_type = tags.value.resource_type # "machine"
      dynamic "tags" {
        for_each = tags.value.tags
        content {
          key   = tags.key
          value = tags.value
        }
      }
    }
  }

  deletion_protection = try(each.value.deletion_protection, false) // false
  unschedulable       = try(each.value.unschedulable, false) // false

  native {
    scaling {
      min_replicas  = each.value.scaling.min_replicas
      max_replicas  = each.value.scaling.max_replicas
      create_policy = try(each.value.scaling.create_policy, "ZoneEquality") // Node pool expansion strategy. ZoneEquality: multiple availability zones are broken up; ZonePriority: the preferred availability zone takes precedence.
    }
    subnet_ids           = each.value.subnet_ids # ["subnet-itb6d123"]
    instance_charge_type = try(each.value.instance_charge_type, "POSTPAID_BY_HOUR") # "PREPAID" Node billing type. PREPAID is a yearly and monthly subscription, POSTPAID_BY_HOUR is a pay-as-you-go plan. The default is POSTPAID_BY_HOUR.
    system_disk {
      disk_type = try(each.value.system_disk.disk_type, "CLOUD_SSD") # Cloud disk type. Valid values: CLOUD_PREMIUM: Premium Cloud Storage, CLOUD_SSD: cloud SSD disk, CLOUD_BSSD: Basic SSD, CLOUD_HSSD: Enhanced SSD.
      disk_size = try(each.value.system_disk.disk_size, 50)
    }
    instance_types     = try(each.value.instance_types, ["SA2.MEDIUM2"]) # ["SA2.MEDIUM2"]
    security_group_ids = try(each.value.security_group_ids, []) #["sg-7tum9120"]
    auto_repair        = try(each.value.auto_repair, false) # false
    dynamic "instance_charge_prepaid" {
      for_each = try(each.value.instance_charge_type, "POSTPAID_BY_HOUR") == "PREPAID" ? [1] : []
      content {
        period     = try(each.value.instance_charge_prepaid.period, 1) #  Postpaid billing cycle, unit (month): 1, 2, 3, 4, 5,, 6, 7, 8, 9, 10, 11, 12, 24, 36, 48, 60.
        renew_flag = try(each.value.instance_charge_prepaid.renew_flag, "NOTIFY_AND_AUTO_RENEW") # NOTIFY_AND_AUTO_RENEW,NOTIFY_AND_MANUAL_RENEW,DISABLE_NOTIFY_AND_MANUAL_RENEW
      }
    }
    management {
      nameservers = try(each.value.management.nameservers, ["183.60.83.19", "183.60.82.98"])
      hosts       = try(each.value.management.hosts, []) # ["192.168.2.42 static.fake.com", "192.168.2.42 static.fake.com2"]
      kernel_args = try(each.value.management.kernel_args, []) # ["kernel.pid_max=65535", "fs.file-max=400000"]
    }
    host_name_pattern = var.node_name_type == "lan-ip" ? null : try(each.value.host_name_pattern, null) # "aaa{R:3}"
    kubelet_args      = try(each.value.kubelet_args, []) # ["allowed-unsafe-sysctls=net.core.somaxconn", "root-dir=/var/lib/test"]
    dynamic "lifecycle" {
      for_each = try(each.value.lifecycle.pre_init, null) == null && try(each.value.lifecycle.post_init, null) == null ? [] : [1]
      content {
        pre_init  = try(each.value.lifecycle.pre_init, null) # "ZWNobyBoZWxsb3dvcmxk"
        post_init = try(each.value.lifecycle.post_init, null) # "ZWNobyBoZWxsb3dvcmxk"
      }
    }
    runtime_root_dir   = try(each.value.runtime_root_dir, "/var/lib/docker")
    enable_autoscaling = try(each.value.enable_autoscaling, true)
    replicas           = try(each.value.replicas, 1) # Desired number of nodes.
    internet_accessible {
      max_bandwidth_out = try(each.value.internet_accessible.max_bandwidth_out, 50) # 50
      charge_type       = try(each.value.internet_accessible.charge_type, "TRAFFIC_POSTPAID_BY_HOUR") # Network billing method. Optional value is TRAFFIC_POSTPAID_BY_HOUR, BANDWIDTH_POSTPAID_BY_HOUR and BANDWIDTH_PACKAGE
      bandwidth_package_id = try(each.value.internet_accessible.charge_type, "TRAFFIC_POSTPAID_BY_HOUR") == "BANDWIDTH_PACKAGE" ? try(each.value.internet_accessible.bandwidth_package_id, null) : null
    }
    dynamic data_disks {
      for_each = each.value.data_disks
      content {
        disk_type             = try(data_disks.value.disk_type, "CLOUD_SSD") #"CLOUD_PREMIUM" alid values: CLOUD_PREMIUM: Premium Cloud Storage, CLOUD_SSD: cloud SSD disk, CLOUD_BSSD: Basic SSD, CLOUD_HSSD: Enhanced SSD, CLOUD_TSSD: Tremendous SSD, LOCAL_NVME: local NVME disk.
        file_system           = try(data_disks.value.file_system ,"ext4")
        disk_size             = try(data_disks.value.disk_size, 100) # 60
        mount_target          = try(data_disks.value.mount_target, "/var/lib/docker")
        auto_format_and_mount = try(data_disks.value.auto_format_and_mount, true) # true
      }
    }
    key_ids = try(each.value.key_ids, null) # ["skey-9pcs2100"]
  }

  dynamic annotations {
    for_each = each.value.annotations
    content {
      name  = annotations.value.name # "node.tke.cloud.tencent.com/test-anno"
      value = annotations.value.value # "test"
    }
  }
}

resource "tencentcloud_kubernetes_health_check_policy" "kubernetes_health_check_policy" {
  for_each = var.health_check_policies
  cluster_id = local.cluster_id
  name       = each.value.name
  dynamic "rules" {
    for_each = each.value.rules
    content {
      name                = rules.value.name # "OOMKilling"
      auto_repair_enabled = try(rules.value.auto_repair_enabled, true)
      enabled             = try(rules.value.enabled, true)
    }
  }
}

resource "tencentcloud_kubernetes_log_config" "kubernetes_log_configs" {
  for_each = var.enable_log_agent ? var.log_configs : {}
  log_config_name = each.value.log_config_name
  cluster_id      = local.cluster_id
  logset_id       = each.value.logset_id
  log_config = jsonencode({
    "apiVersion" : "cls.cloud.tencent.com/v1",
    "kind" : "LogConfig",
    "metadata" : {
      "name" : each.value.log_config_name
    },
    "spec" : each.value.spec
  })
}

resource "tencentcloud_kubernetes_auth_attachment" "auth_attach" {
  count = var.enable_pod_identity ? 1 : 0
  cluster_id                              = local.cluster_id
  use_tke_default                         = true
  auto_create_discovery_anonymous_auth    = true
  auto_create_oidc_config                 = true
  auto_install_pod_identity_webhook_addon = true
  depends_on = [
    tencentcloud_kubernetes_node_pool.this,
    tencentcloud_kubernetes_serverless_node_pool.this,
    tencentcloud_kubernetes_native_node_pool.native_node_pools
  ]
}

data "tencentcloud_kubernetes_clusters" "cluster" {
  depends_on = [tencentcloud_kubernetes_cluster_endpoint.endpoints]
  cluster_id = local.cluster_id
}