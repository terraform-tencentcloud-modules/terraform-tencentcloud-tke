variable "uin" {
  type = string
  default = ""
}
variable "cluster_id" {
  type = string
  default = ""
}

variable "oidc_client_id" {
  type = string
  default = "sts.cloud.tencent.com"
}
variable "roles" {
  type = any
  default = {}
  description = "see `tencentcloud_cam_role` `tencentcloud_cam_role_policy_attachment_by_name`"
}
variable "policies" {
  type = any
  default = {}
  description = "Map of policies to create. Name is the map key.see `tencentcloud_cam_policy` "
}