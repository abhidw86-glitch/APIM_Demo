locals {
  common_tags = merge({
    project     = var.project_name
    environment = "demo"
    managed_by  = "terraform"
  }, var.tags)
}

resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_application_insights" "gateway" {
  name                = "appi-${var.project_name}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  application_type    = "web"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_api_management" "gateway" {
  name                = var.apim_name
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Consumption_0"
  tags                = local.common_tags
}

resource "azurerm_api_management_logger" "application_insights" {
  name                = "application-insights"
  api_management_name = azurerm_api_management.gateway.name
  resource_group_name = azurerm_resource_group.demo.name
  resource_id         = azurerm_application_insights.gateway.id

  application_insights {
    instrumentation_key = azurerm_application_insights.gateway.instrumentation_key
  }
}

resource "azurerm_api_management_api" "inventory" {
  name                  = "inventory-api"
  resource_group_name   = azurerm_resource_group.demo.name
  api_management_name   = azurerm_api_management.gateway.name
  revision              = "1"
  display_name          = "Inventory API"
  path                  = "v1/inventory"
  protocols             = ["https"]
  subscription_required = true
  service_url           = "https://example.invalid"

  import {
    content_format = "openapi+json"
    content_value  = file("${path.module}/api-specs/inventory-api.json")
  }
}

resource "azurerm_api_management_api_policy" "inventory" {
  api_name            = azurerm_api_management_api.inventory.name
  api_management_name = azurerm_api_management.gateway.name
  resource_group_name = azurerm_resource_group.demo.name
  xml_content         = file("${path.module}/policies/inventory.xml")
}

resource "azurerm_api_management_diagnostic" "application_insights" {
  identifier                = "applicationinsights"
  api_management_name       = azurerm_api_management.gateway.name
  resource_group_name       = azurerm_resource_group.demo.name
  api_management_logger_id  = azurerm_api_management_logger.application_insights.id
  always_log_errors         = true
  sampling_percentage       = 100
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 8192
  }

  frontend_response {
    body_bytes = 8192
  }

  backend_request {
    body_bytes = 8192
  }

  backend_response {
    body_bytes = 8192
  }
}