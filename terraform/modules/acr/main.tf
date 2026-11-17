resource "azurerm_container_registry" "this" {
  name                = replace("acr${var.project_name}${var.env}", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = true
}
