resource "tencentcloud_vpc" "vpc" {
  cidr_block = var.network_cidr
  name       = var.vpc_name
  tags       = var.tags
}

resource "tencentcloud_subnet" "subnet" {
  availability_zone = var.available_zone
  cidr_block        = var.network_cidr
  name              = var.subnet_name
  vpc_id            = tencentcloud_vpc.vpc.id
  tags              = var.tags
}

resource "tencentcloud_security_group" "sg" {
  name        = var.security_group_name
  description = "example security groups for kubernetes networks"
  tags        = var.tags
}

resource "tencentcloud_security_group_lite_rule" "sg_rules" {
  security_group_id = tencentcloud_security_group.sg.id
  ingress           = var.security_ingress_rules
  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL"
  ]
}