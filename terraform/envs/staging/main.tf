terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "location" {
  type = string
}

variable "env" {
  type = string
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

module "network" {
  source   = "../../modules/network"
  env      = var.env
  location = var.location
}

module "vm" {
  source              = "../../modules/vm"
  env                 = var.env
  location            = var.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.vm_subnet_id
  ssh_public_key      = var.ssh_public_key
}

module "acr" {
  source              = "../../modules/acr"
  env                 = var.env
  location            = var.location
  resource_group_name = module.network.resource_group_name
}

module "postgres" {
  source              = "../../modules/postgres"
  env                 = var.env
  location            = var.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.database_subnet_id
  virtual_network_id   = module.network.virtual_network_id
  admin_password      = var.postgres_admin_password
}

output "vm_public_ip" {
  value = module.vm.public_ip
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "postgres_fqdn" {
  value = module.postgres.fully_qualified_domain_name
}
