# Basic
variable "available_zone" {
  type        = string
  default     = "ap-guangzhou-3"
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
variable "vpc_name" {
  type        = string
  default     = "example-vpc"
  description = "Specify custom VPC Name."
}

variable "subnet_name" {
  type        = string
  default     = "example-subnet"
  description = "Specify custom Subnet Name."
}

variable "security_group_name" {
  type        = string
  default     = "example-security-group"
  description = "Specify custom Security Group Name."
}

variable "network_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Specify VPC and subnet CIDR."
}

variable "security_ingress_rules" {
  type = list(string)
  default = [
    "ACCEPT#10.0.0.0/16#ALL#ALL",
    "ACCEPT#172.16.0.0/22#ALL#ALL",
    "DROP#0.0.0.0/0#ALL#ALL"
  ]
  description = "Specify public access policy. You can optionally use simple [\"ACCEPT#0.0.0.0/0#ALL#ALL\"] to allow all public access (not recommended)."
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
  default     = "tlinux2.2(tkernel3)x86_64"
  description = "Cluster operation system image name."
}

variable "cluster_public_access" {
  type        = bool
  default     = true
  description = "Specify whether to open cluster public access."
}

variable "cluster_private_access" {
  type        = bool
  default     = true
  description = "Specify whether to open cluster private access."
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