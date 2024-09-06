
resource "tencentcloud_security_group" "sgs" {
  for_each = var.security_groups
  name = try(each.value.name, each.key)
}

data "tencentcloud_security_groups" "existed" {
}

locals {
  sg_name_to_id = merge(
    {
      for k, v in {for sg in data.tencentcloud_security_groups.existed.security_groups : sg.name => sg.security_group_id...}: k => v[0]
    },
    {
      for k, sg in tencentcloud_security_group.sgs: sg.name => sg.id
    }
  )
}

resource "tencentcloud_security_group_rule_set" "base" {
  for_each = var.security_groups
  security_group_id = tencentcloud_security_group.sgs[each.key].id

  dynamic ingress {
    for_each = try(each.value.ingress, [])
    content {
      action      = try(ingress.value.action, "ACCEPT")  # ACCEPT and DROP
      cidr_block  = try(ingress.value.source_security_group, null) == null ? try(ingress.value.cidr_block, "") : null # "10.0.0.0/22"
      protocol    = try(ingress.value.protocol, "ALL") # "TCP"  # TCP, UDP and ICMP
      port        = try(ingress.value.protocol, "ALL") == "ALL" ? null : ingress.value.port # "80-90" # 80, 80,90 and 80-90
      description = try(ingress.value.description, "")
      source_security_id = try(ingress.value.source_security_group, null) == null ? null : local.sg_name_to_id[ingress.value.source_security_group]
    }
  }

  dynamic ingress {
    for_each = try(each.value.default_ingress_deny_all, true) ? ["1"]: []
    content {
      action      = "DROP"
      cidr_block  = "0.0.0.0/0"
      protocol    = "ALL"
      port        = "ALL"
      description = "ingress default deny all traffic"
    }
  }

  dynamic egress {
    for_each = try(each.value.egress, [])
    content {
      action                 = try(egress.value.action, "ACCEPT")  # ACCEPT and DROP
      cidr_block = egress.value.cidr_block
      description            = try(egress.value.description, "") #
      port = egress.value.port
      protocol  = try(egress.value.protocol, "ALL")
    }
  }

  dynamic egress {
    for_each = try(each.value.default_egress_allow_all, true) ? ["1"]: []
    content {
      action      = "ACCEPT"
      cidr_block  = "0.0.0.0/0"
      protocol    = "ALL"
      port        = "ALL"
      description = "egress default allow all traffic"
    }
  }
}