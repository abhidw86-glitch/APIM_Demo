output "resource_group_name" {
  description = "Resource group containing the demo."
  value       = azurerm_resource_group.demo.name
}

output "apim_name" {
  description = "Provisioned API Management service name."
  value       = azurerm_api_management.gateway.name
}

output "inventory_api_url" {
  description = "URL used by the traffic demonstration script."
  value       = "${azurerm_api_management.gateway.gateway_url}/v1/inventory/items"
}

output "application_insights_name" {
  description = "Application Insights resource for gateway telemetry."
  value       = azurerm_application_insights.gateway.name
}