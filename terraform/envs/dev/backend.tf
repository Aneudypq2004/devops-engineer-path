terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateexample"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
}
