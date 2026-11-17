variable "project_name" {
  type    = string
  default = "devopslab"
}

variable "env" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "virtual_network_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "pgadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}
