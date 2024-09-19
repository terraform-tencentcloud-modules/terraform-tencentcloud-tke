resource "tencentcloud_kubernetes_auth_attachment" "auth_attach" {
  cluster_id                              = var.cluster_id
  use_tke_default                         = true
  auto_create_discovery_anonymous_auth    = true
  auto_create_oidc_config                 = true
  auto_install_pod_identity_webhook_addon = true
}


resource "tencentcloud_cam_role" "roles" {

  for_each = var.roles
  document      = jsonencode(
  {
  "version": "2.0",
  "statement": [
    {
      "action": "name/sts:AssumeRoleWithWebIdentity",
      "effect": "allow",
      "principal": {
        "federated": [
          "qcs::cam::uin/${var.uin}:oidc-provider/${var.cluster_id}"
        ]
      },
      "condition": {
        "string_equal": {
          "oidc:iss": [tencentcloud_kubernetes_auth_attachment.auth_attach.tke_default_issuer],
          "oidc:aud": ["${var.oidc_client_id}"]
        }
      }
    }
  ]
  }
  )
  name          = try(each.value.name, each.key)
  session_duration = 7200
  console_login = try(each.value.console_login, false)
  description   = try(each.value.description, each.key)
  tags          = try(each.value.tags, {})
}

locals {
  policy_attachments = flatten([
    for role_key, role in var.roles: [
      for policy in try(role.policies, []): {
        k = format("%s_%s", try(role.name, role_key), policy)
        role_name   = try(role.name, role_key)
        policy_name = policy
      }
    ]
  ])
  policy_attachment_map = {
    for role_policy in local.policy_attachments: role_policy.k => role_policy
  }
}

resource "tencentcloud_cam_role_policy_attachment_by_name" "role_policy_attachment_basic" {
  depends_on = [tencentcloud_cam_role.roles, tencentcloud_cam_policy.policies]
  for_each = local.policy_attachment_map
  role_name   = each.value.role_name
  policy_name = each.value.policy_name
}


# create policies
resource "tencentcloud_cam_policy" "policies" {
  for_each = var.policies
  name        = each.key   // ForceNew
  document    = try(each.value.document, null)
  description = try(each.value.description, "")
}
