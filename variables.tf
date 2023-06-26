# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

variable "create_public_access" {
  type        = bool
  description = "Flag to set whether to create remote management network security group"
  default     = true
}

variable "win_vm_deploy" {
  type        = number
  description = "Whether to deploy the Windows 10 VM"
  default     = 1
}

variable "mgmt_rdp_source_address_prefix" {
  type        = string
  description = "Source address for NSG rule to allow management access (RDP)"
  default     = ""
}

variable "rdp_windows_width" {
  type        = string
  description = "Windows RDP windows width setting"
  default     = "1600"
}

variable "rdp_windows_height" {
  type        = string
  description = "Windows RDP windows height setting"
  default     = "1200"
}


variable "resource_group" {
  default = "rg-aml-terraform-demo"
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