variable "project_name" {
  type    = string
  default = "devops-lab"
}

variable "env" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vm_subnet_address_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "database_subnet_address_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "ssh_source_address" {
  type    = string
  default = "*"
}
