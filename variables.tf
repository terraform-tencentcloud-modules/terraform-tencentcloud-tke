variable "create_cluster" {
  type = bool
  default = true
  description = "create cluster or not. If not, must specify a cluster id"
}
variable "cluster_id" {
  type = string
  default = ""
  description = "existing cluster id, used when create_cluster is false"
}
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
  description = "Name to use on cluster security group"
}

variable "node_security_group_id" {
  description = "Name to use on node security group"
  type        = string
  default     = null
}

variable "network_type" {
  description = "Cluster network type, GR or VPC-CNI. Default is GR."
  type        = string
  default     = "GR"
}

variable "eni_subnet_ids" {
  description = "Subnet Ids for cluster with VPC-CNI network mode. This field can only set when field network_type is 'VPC-CNI'."
  type        = list(string)
  default     = []
}

variable "claim_expired_seconds" {
  type        = number
  default     = 300
  description = "Claim expired seconds to recycle ENI. This field can only set when field network_type is 'VPC-CNI'. claim_expired_seconds must greater or equal than 300 and less than 15768000."
}

variable "cluster_max_service_num" {
  type        = number
  default     = 256
  description = "A network address block of the service. Different from vpc cidr and cidr of other clusters within this vpc. Must be in 10./192.168/172.[16-31] segments."
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
  description = "Cluster cidr, conflicts with its subnet. set to \"\" when network_type is VPC-CNI"
}

variable "cluster_os" {
  type        = string
  default     = "tlinux2.2(tkernel3)x86_64"
  description = "Cluster operation system image name."
}

variable "container_runtime" {
  type        = string
  default     = "containerd"
  description = "Runtime type of the cluster, the available values include: 'docker' and 'containerd'.The Kubernetes v1.24 has removed dockershim, so please use containerd in v1.24 or higher.Default is 'docker'."
}

variable "cluster_level" {
  type        = string
  default     = "L5"
  description = "Specify cluster level, valid for managed cluster, use data source tencentcloud_kubernetes_cluster_levels to query available levels. Available value examples L5, L20, L50, L100"
}

variable "cluster_max_pod_num" {
  type = number
  default = 256
  description = "The maximum number of Pods per node in the cluster. Default is 256. The minimum value is 4. When its power unequal to 2, it will round upward to the closest power of 2"
}

variable "create_endpoint_with_cluster" {
  type = bool
  default = true
  description = "If set to false, cluster_public_access and cluster_private_access will be disabled. The endpoints will be created with the setting of cluster_endpoints"
}

variable "cluster_public_access" {
  type        = bool
  default     = false
  description = "Specify whether to open cluster public access."
}

variable "cluster_internet_domain" {
  type = string
  default = null
  description = "Domain name for cluster Kube-apiserver internet access. Be careful if you modify value of this parameter, the cluster_external_endpoint value may be changed automatically too"
}

variable "cluster_private_access" {
  type        = bool
  default     = false
  description = "Specify whether to open cluster private access."
}

variable "cluster_intranet_domain" {
  type = string
  default = null
  description = "Domain name for cluster Kube-apiserver intranet access. Be careful if you modify value of this parameter, the pgw_endpoint value may be changed automatically too."
}

variable "cluster_private_access_subnet_id" {
  type        = string
  default     = null
  description = "Specify subnet_id for cluster private access."
}

variable "create_workers_with_cluster" {
  type = bool
  default = false
  description = "If set to false, there won't be node created with cluster. All nodes will be created in node groups"
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

variable "enable_log_agent" {
  type        = bool
  default     = false
  description = "Specify weather the Log agent enabled. "
}

variable "kubelet_root_dir" {
  type        = string
  default     = ""
  description = "Kubelet root directory as the literal."
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

variable "deletion_protection" {
  type = bool
  default = false
  description = "Indicates whether cluster deletion protection is enabled. Default is false."
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

################################################################################
# Self Managed Serverless Node Group
################################################################################

variable "self_managed_serverless_node_groups" {
  description = "Map of self-managed serverless node pool definitions to create. see `tencentcloud_kubernetes_serverless_node_pool` "
  type        = any
  default     = {}
}

####
variable "private_access_subnet_by_key" {
  type = bool
  default = false
}
variable "private_access_subnet_id_map" {
  type = map(string)
  default = {}
}
variable "private_access_subnet_key" {
  type = string
  default = ""
}
