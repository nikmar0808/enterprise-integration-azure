resource "azurerm_api_management" "dev" {
  name                = "eai-dev-apim-glbunq"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  publisher_name      = "Enterprise Integration Project"
  publisher_email     = "nikmar0808@users.noreply.github.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "dev" {
  name                = "enterprise-integration"
  resource_group_name = azurerm_resource_group.dev.name
  api_management_name = azurerm_api_management.dev.name
  revision            = "1"
  display_name        = "Enterprise Integration API"
  path                = ""
  protocols           = ["https"]
  service_url         = "http://${azurerm_public_ip.vm.ip_address}:8081"
}

resource "azurerm_api_management_api_operation" "dev_proxy" {
  operation_id        = "proxy-all"
  api_name            = azurerm_api_management_api.dev.name
  api_management_name = azurerm_api_management.dev.name
  resource_group_name = azurerm_resource_group.dev.name
  display_name        = "Proxy all"
  method              = "*"
  url_template        = "/*"

  response {
    status_code = 200
  }
}

output "apim_gateway_url" { value = azurerm_api_management.dev.gateway_url }
