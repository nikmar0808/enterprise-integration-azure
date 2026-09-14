resource "azurerm_api_management" "prod" {
  name                = "eai-prod-apim-glbunq"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  publisher_name      = "Enterprise Integration Project"
  publisher_email     = "nikmar0808@users.noreply.github.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "prod" {
  name                = "enterprise-integration"
  resource_group_name = azurerm_resource_group.prod.name
  api_management_name = azurerm_api_management.prod.name
  revision            = "1"
  display_name        = "Enterprise Integration API"
  path                = ""
  protocols           = ["https"]
  service_url         = "http://${azurerm_public_ip.vm.ip_address}:8081"
}

resource "azurerm_api_management_api_operation" "prod_proxy" {
  operation_id        = "proxy-all"
  api_name            = azurerm_api_management_api.prod.name
  api_management_name = azurerm_api_management.prod.name
  resource_group_name = azurerm_resource_group.prod.name
  display_name        = "Proxy all"
  method              = "*"
  url_template        = "/*"

  response {
    status_code = 200
  }
}

output "apim_gateway_url" { value = azurerm_api_management.prod.gateway_url }
