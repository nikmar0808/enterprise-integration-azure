resource "azurerm_api_management" "uat" {
  name                = "eai-uat-apim-glbunq"
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name
  publisher_name      = "Enterprise Integration Project"
  publisher_email     = "nikmar0808@users.noreply.github.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "uat" {
  name                = "enterprise-integration"
  resource_group_name = azurerm_resource_group.uat.name
  api_management_name = azurerm_api_management.uat.name
  revision            = "1"
  display_name        = "Enterprise Integration API"
  path                = ""
  protocols           = ["https"]
  service_url         = "http://${azurerm_public_ip.vm.ip_address}:8081"
}

resource "azurerm_api_management_api_operation" "uat_proxy" {
  operation_id        = "proxy-all"
  api_name            = azurerm_api_management_api.uat.name
  api_management_name = azurerm_api_management.uat.name
  resource_group_name = azurerm_resource_group.uat.name
  display_name        = "Proxy all"
  method              = "*"
  url_template        = "/*"

  response {
    status_code = 200
  }
}

output "apim_gateway_url" { value = azurerm_api_management.uat.gateway_url }
