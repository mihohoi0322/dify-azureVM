variable "subscription_id" {
  type = string
  default = ""
}

variable "tenant_id" {
  type = string
  default = ""
}

variable "resource_group_name" {
  type    = string
  default = "rg-dify-vm"
}

variable "location" {
  type    = string
  default = "japaneast"
}

variable "vnet_dify_name" {
  type    = string
  default = "dify-vnet"
}

variable "subnet_dify_name" {
  type    = string
  default = "dify-subnet"
  
}

variable "nsg_dify_name" {
  type    = string
  default = "dify-nsg"
}

variable "vm_dify_name" {
  type    = string
  default = "dify-vm"
}

# Windows VM関連設定
variable "windows_subnet_name" {
  type    = string
  default = "jumpbox-subnet"
}

variable "windows_subnet_prefix" {
  type    = string
  default = "10.0.20.0/24"
}

variable "windows_nsg_name" {
  type    = string
  default = "jumpbox-nsg"
}

variable "windows_nic_name" {
  type    = string
  default = "jumpbox-nic"
}

variable "windows_vm_name" {
  type    = string
  default = "jumpbox"
}

variable "windows_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "windows_admin_username" {
  type    = string
  default = "adminuser"
}

# Bastion関連設定
variable "bastion_subnet_name" {
  type    = string
  default = "AzureBastionSubnet" 
}

variable "bastion_subnet_prefix" {
  type    = string
  default = "10.0.30.0/24"
}

variable "bastion_ip_name" {
  type    = string
  default = "bastion-ip"
}

variable "bastion_name" {
  type    = string
  default = "dify-bastion"
}

# Dify VM関連追加設定
variable "dify_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "dify_admin_username" {
  type    = string
  default = "difyadmin"
}