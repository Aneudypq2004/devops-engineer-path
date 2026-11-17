output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "vm_subnet_id" {
  value = azurerm_subnet.vm.id
}

output "database_subnet_id" {
  value = azurerm_subnet.database.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}
