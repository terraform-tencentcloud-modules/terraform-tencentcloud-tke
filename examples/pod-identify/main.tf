data "tencentcloud_user_info" "this" {}

locals {
  owner_uin = data.tencentcloud_user_info.this.owner_uin
  cluster_id = "cls-xxxx"
  tags = {
    created: "terraform"
  }
}

module "pod-identify" {
  source = "./modules/tke_pod_identify"
  uin = local.owner_uin
  cluster_id = local.cluster_id
  roles = {
    tke_pod_identify_demo = {
      name          = "tke_pod_identify_demo"
      console_login = false
      description   = "tke_pod_identify_demo"
      tags          = local.tags
      policies = [
        "TICRoleInInfrastructureAsCode"
      ]
    }
  }
  policies = {}
}