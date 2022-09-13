# Terraform Kubernetes example based on TencentCloud Tke Module

Provides example to show how to use kubernetes provider to create a simple Kubernetes application based on TencentCloud TKE module.


## Usage

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note, this example may create resources which cost money. Run `terraform destroy` if you don't need these resources.

## Variables
|Name|Type|Default|Description|
|:---:|:---:|:---:|:---|
| accept_ip | string | None | Specify which ip or CIDR block which was public access allowed |
| region | string | ap-guangzhou | Provider region |
| available_zone | string | ap-guangzhou-3 | Provider available zone which belongs to region e.g. |

## Outputs

|Name|Description|
|:---:|:---|
|load_balancer_ip|Public ip address exposed by load balancer after application deploy finished.|