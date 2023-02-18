# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

variable "resource_group" {
  default = "aml-terraform-demo"
}

variable "workspace_display_name" {
  default = "aml-terraform-demo"
}

variable "location" {
  default = "UK South"
}

variable "deploy_aks" {
  default = false
}

variable "jumphost_username" {
  default = "azureuser"
}

variable "jumphost_password" {
  default = "ThisIsNotVerySecure!"
}

variable "prefix" {
  type    = string
  default = "aml"
}

resource "random_string" "postfix" {
  length  = 6
  special = false
  upper   = false
}

variable "tags" {
  description = "Tags to apply to Azure Virtual Machine Scale"
  type        = map(string)
  default     = {}
}