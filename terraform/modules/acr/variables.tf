variable "project_name" {
  type    = string
  default = "devopslab"
}

variable "env" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}
