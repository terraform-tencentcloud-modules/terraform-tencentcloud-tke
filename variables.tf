# Basic
variable "available_zone" {
  type        = string
  default     = null
  description = "Specify available zone of VPC subnet and TKE nodes."
}

variable "create_cam_strategy" {
  type        = bool
  default     = true
  description = "Specify whether to create CAM role and relative TKE essential policy. Set to false if you've enable by using TencentCloud Console."
}

variable "tags" {
  type = map(string)
  default = {
    terraform = "example"
  }
  description = "Tagged for all associated resource of this module."
}

# Networks
variable "vpc_id" {
  type        = string
  default     = null
  description = "Specify the vpc_id of tke cluster."
}

variable "intranet_subnet_id" {
  type        = string
  default     = ""
  description = "Specify custom Subnet id for intranet."
}

variable "cluster_security_group_id" {
  type        = string
  default     = null
  description = ""
}

variable "node_security_group_id" {
  description = "Name to use on node security group"
  type        = string
  default     = null
}

# TKE
variable "cluster_name" {
  type        = string
  default     = "example-cluster"
  description = "TKE managed cluster name."
}

variable "cluster_version" {
  type        = string
  default     = "1.22.5"
  description = "Cluster kubernetes version."
}

variable "cluster_cidr" {
  type        = string
  default     = "172.16.0.0/22"
  description = "Cluster cidr, conflicts with its subnet."
}

variable "cluster_os" {
  type        = string
  default     = "tlinux2.4(tkernel4)x86_64"
  description = "Cluster operation system image name."
}

variable "cluster_public_access" {
  type        = bool
  default     = false
  description = "Specify whether to open cluster public access."
}

variable "cluster_private_access" {
  type        = bool
  default     = false
  description = "Specify whether to open cluster private access."
}

variable "cluster_private_access_subnet_id" {
  type        = string
  default     = null
  description = ""
}

variable "worker_count" {
  type        = number
  default     = 1
  description = "Specify node count."
}

variable "worker_instance_type" {
  type        = string
  default     = "S5.MEDIUM2"
  description = "Cluster node instance type."
}

variable "worker_bandwidth_out" {
  type    = number
  default = null
}

variable "enable_event_persistence" {
  type        = bool
  default     = false
  description = "Specify weather the Event Persistence enabled. "
}

variable "enable_cluster_audit_log" {
  type        = bool
  default     = false
  description = "Specify weather the Cluster Audit enabled. NOTE: Enable Cluster Audit will also auto install Log Agent."
}

variable "event_log_set_id" {
  type        = string
  default     = null
  description = "Specify id of existing CLS log set, or auto create a new set by leave it empty. "
}

variable "cluster_audit_log_set_id" {
  type        = string
  default     = null
  description = "Specify id of existing CLS log set, or auto create a new set by leave it empty. "
}

variable "event_log_topic_id" {
  type        = string
  default     = null
  description = "Specify id of existing CLS log topic, or auto create a new topic by leave it empty."
}

variable "cluster_audit_log_topic_id" {
  type        = string
  default     = null
  description = "Specify id of existing CLS log topic, or auto create a new topic by leave it empty. "
}

variable "cluster_service_cidr" {
  type        = string
  default     = null
  description = "A network address block of the service. Different from vpc cidr and cidr of other clusters within this vpc. Must be in 10./192.168/172.[16-31] segments."
}

variable "enhanced_monitor_service" {
  type        = bool
  default     = true
  description = "To specify whether to enable cloud monitor service."
}

################################################################################
# TKE Addons
################################################################################

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`, see `tencentcloud_kubernetes_addon_attachment`"
  type        = any
  default     = {}
}

################################################################################
# Self Managed Node Group
################################################################################

variable "self_managed_node_groups" {
  description = "Map of self-managed node pool definitions to create. see `tencentcloud_kubernetes_node_pool` "
  type        = any
  default     = {}
}
