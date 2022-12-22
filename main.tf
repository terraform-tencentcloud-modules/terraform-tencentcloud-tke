resource "random_password" "worker_pwd" {
  length           = 12
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "tencentcloud_kubernetes_cluster" "cluster" {
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_cidr                    = var.cluster_cidr
  cluster_os                      = var.cluster_os
  cluster_internet                = var.cluster_public_access
  cluster_internet_security_group = var.cluster_public_access ? tencentcloud_security_group.sg.id : null
  cluster_intranet                = var.cluster_private_access
  cluster_intranet_subnet_id      = var.cluster_private_access ? tencentcloud_subnet.subnet.id : null
  vpc_id                          = tencentcloud_vpc.vpc.id

  worker_config {
    availability_zone  = var.available_zone
    count              = var.worker_count
    instance_type      = var.worker_instance_type
    subnet_id          = tencentcloud_subnet.subnet.id
    security_group_ids = [tencentcloud_security_group.sg.id]
    # check the internal message on your account message center if needed
    password = random_password.worker_pwd.result
  }

  tags = var.tags
}