locals {
  cluster_id = "cls-xxxxxx"
  tcr_id = "tcr-xxxxx"
  user_name = "1000xxxxxx"
  token = "xxxxxx"
  tcr_name = "tcr"
  cluster_region = "nj"
  cluster_longregion = "ap-nanjing"
  internal_ip = "1.2.3.4"

}


module "addon" {
  source = "../.."
  create_cam_strategy = false
  create_cluster = false
  cluster_id = local.cluster_id
  cluster_addons = {
    cfs = {
      legacy = false
      addon_version = "1.1.5"
    },
    cos = {
      legacy = false
      addon_version = "1.0.5"
    },
    tcr = {
      legacy = false
      addon_version = "1.0.2"
      raw_values = {
        global = {
          imagePullSecretsCrs = [
            {
              name = "${local.tcr_id}-vpc"
              namespaces = "*"
              serviceAccounts = "*"
              type = "docker"
              dockerUsername = local.user_name
              dockerPassword = local.token
              dockerServer = "${local.tcr_name}-vpc.tencentcloudcr.com"
            },
            {
              name = "${local.tcr_id}-public"
              namespaces = "*"
              serviceAccounts = "*"
              type = "docker"
              dockerUsername = local.user_name
              dockerPassword = local.token
              dockerServer = "${local.tcr_name}.tencentcloudcr.com"
            }
          ]
          cluster = {
            region = local.cluster_region
            longregion = local.cluster_longregion
          }
          hosts = [
            {
              domain = "${local.tcr_name}-vpc.tencentcloudcr.com"
              ip = local.internal_ip
              disabled = false
            },
            {
              domain = "${local.tcr_name}.tencentcloudcr.com"
              ip = local.internal_ip
              disabled = false
            }
          ]
        }
      }
    }

  }
}