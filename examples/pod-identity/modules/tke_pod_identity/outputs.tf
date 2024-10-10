output "role_arns" {
  value = {
    for role_key, role in tencentcloud_cam_role.roles: role_key => format("qcs::cam::uin/%s:roleName/%s", var.uin, role.name)
  }
}

output "oidc_config_id" {
  value = tencentcloud_kubernetes_auth_attachment.auth_attach.id
}
output "oidc_config_tke_default_issuer" {
  value = tencentcloud_kubernetes_auth_attachment.auth_attach.tke_default_issuer
}
output "oidc_config_tke_default_jwks_uri" {
  value = tencentcloud_kubernetes_auth_attachment.auth_attach.tke_default_jwks_uri
}