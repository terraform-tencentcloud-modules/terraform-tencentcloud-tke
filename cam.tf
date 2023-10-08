resource "tencentcloud_cam_role" "TKE_QSCRole" {
  count       = var.create_cam_strategy ? 1 : 0
  name        = "TKE_QSCRole"
  document    = <<EOF
{
  "statement": [
    {
      "action":"name/sts:AssumeRole",
      "effect":"allow",
      "principal":{
        "service":"ccs.qcloud.com"
      }
    }
  ],
  "version":"2.0"
}
EOF
  description = "The current role is the TKE service role, which will access your other service resources within the scope of the permissions of the associated policy."
}

resource "tencentcloud_cam_policy" "OpsMgr" {

  count = var.create_cam_strategy ? 1 : 0

  name = "TF_QcloudAccessForTKERoleInOpsManagement"
  document = jsonencode({
    "version" : "2.0",
    "statement" : [
      {
        "action" : [
          "cls:listTopic",
          "cls:getTopic",
          "cls:createTopic",
          "cls:modifyTopic",
          "cls:deleteTopic",
          "cls:listLogset",
          "cls:getLogset",
          "cls:createLogset",
          "cls:modifyLogset",
          "cls:deleteLogset",
          "cls:listMachineGroup",
          "cls:getMachineGroup",
          "cls:createMachineGroup",
          "cls:modifyMachineGroup",
          "cls:deleteMachineGroup",
          "cls:getMachineStatus",
          "cls:pushLog",
          "cls:searchLog",
          "cls:downloadLog",
          "cls:getCursor",
          "cls:getIndex",
          "cls:modifyIndex",
          "cls:agentHeartBeat",
          "cls:CreateChart",
          "cls:ModifyChart",
          "cls:DeleteChart",
          "cls:CreateDashboard",
          "cls:ModifyDashboard",
          "cls:DeleteDashboard",
          "cls:GetChart",
          "cls:ListChart",
          "cls:ListDashboard",
          "cls:GetDashboard",
          "cls:getConfig",
          "cls:CreateConfig",
          "cls:DeleteConfig",
          "cls:ModifyConfig",
          "cls:DescribeConfigs",
          "cls:DescribeMachineGroupConfigs",
          "cls:DeleteConfigFromMachineGroup",
          "cls:ApplyConfigToMachineGroup",
          "cls:DescribeConfigMachineGroups",
          "cls:ModifyTopic",
          "cls:DeleteTopic",
          "cls:CreateTopic",
          "cls:DescribeTopics",
          "cls:CreateLogset",
          "cls:DeleteLogset",
          "cls:DescribeLogsets",
          "cls:CreateIndex",
          "cls:ModifyIndex",
          "cls:CreateMachineGroup",
          "cls:DeleteMachineGroup",
          "cls:DescribeMachineGroups",
          "cls:ModifyMachineGroup"
        ],
        "resource" : ["*"],
        "effect" : "allow"
      }
    ]
  })
}

resource "tencentcloud_cam_policy" "QCA" {
  count = var.create_cam_strategy ? 1 : 0

  name = "TF_QcloudAccessForTKERole"
  document = jsonencode({
    "version" : "2.0",
    "statement" : [
      {
        "action" : [
          "cvm:DescribeInstances",
          "tag:*",
          "clb:*",
          "tke:*", // Modify ccr:Describe* to tke
          "cvm:*Cbs*",
          "cls:pushLog",
          "cls:searchLog",
          "cls:listLogset",
          "cls:getLogset",
          "cls:listTopic",
          "cls:getTopic",
          "cls:agentHeartBeat",
          "cls:getConfig",
          "vpc:DescribeSubnet",
          "vpc:DescribeSubnetEx",
          "vpc:DescribeCcnAttachedInstances",
          "cvm:AllocateAddresses",
          "cvm:DescribeAddresses",
          "vpc:DescribeNetworkInterfaces",
          "cvm:AssociateAddress",
          "cvm:DisassociateAddress",
          "cvm:ReleaseAddresses",
          "ssl:DescribeCertificateDetail",
          "ssl:UploadCertificate",
          "cvm:DescribeSnapshots",
          "cvm:CreateSnapshot",
          "cvm:DeleteSnapshot",
          "cvm:BindAutoSnapshotPolicy",
          "cvm:CreateSecurityGroupPolicy",
          "cvm:DeleteSecurityGroupPolicy",
          "cvm:DescribeSecurityGroupPolicys",
          "vpc:DetachNetworkInterface",
          "vpc:DeleteNetworkInterface",
          "monitor:DescribeStatisticData",
          "vpc:DescribeBandwidthPackages",
          "cam:ListMaskedSubAccounts",
          "cam:GetUserBasicInfo"
        ],
        "resource" : ["*"],
        "effect" : "allow"
      }
    ]
  })
}

resource "tencentcloud_cam_role_policy_attachment" "QCS_OpsMgr" {
  count = var.create_cam_strategy ? 1 : 0

  role_id   = lookup(tencentcloud_cam_role.TKE_QSCRole.0, "id")
  policy_id = lookup(tencentcloud_cam_policy.OpsMgr.0, "id")
}

resource "tencentcloud_cam_role_policy_attachment" "QCS_QCA" {
  count = var.create_cam_strategy ? 1 : 0

  role_id   = lookup(tencentcloud_cam_role.TKE_QSCRole.0, "id")
  policy_id = lookup(tencentcloud_cam_policy.QCA.0, "id")
}