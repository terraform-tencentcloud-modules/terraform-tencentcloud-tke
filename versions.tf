terraform {
  required_version = ">= 0.13"
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = ">=1.79.2"
    }
  }
}