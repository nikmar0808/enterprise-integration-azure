resource "azurerm_user_assigned_identity" "vm" {
  name                = "eai-prod-vm-id"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
}

# Pull-only access to the shared registry — the VM never needs push
# permission, matching the AWS EC2 instance role's pull-only ECR scope.
resource "azurerm_role_assignment" "vm_acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}

# This part is to be uncommented after 10.3.6 and befor ethe next terraform apply is run.
# data "azuread_service_principal" "gha_deploy_prod" {
#   client_id = "ad2adba6-7d1e-4e79-9d6d-4d7300b7581c"
# }

# resource "azurerm_role_assignment" "gha_prod_vm_runcommand" {
#   scope                = azurerm_linux_virtual_machine.prod.id
#   role_definition_name = "Virtual Machine Contributor"
#   principal_id         = data.azuread_service_principal.gha_deploy_prod.object_id
# }

# resource "azurerm_role_assignment" "gha_prod_kv_secrets_user" {
#   scope                = azurerm_key_vault.prod.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = data.azuread_service_principal.gha_deploy_prod.object_id
# }
