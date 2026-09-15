resource "azurerm_user_assigned_identity" "vm" {
  name                = "eai-uat-vm-id"
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name
}

# Pull-only access to the shared registry — the VM never needs push
# permission, matching the AWS EC2 instance role's pull-only ECR scope.
resource "azurerm_role_assignment" "vm_acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}

data "azuread_service_principal" "gha_deploy_uat" {
  client_id = "ee3d709e-2cc9-4a3c-b274-cc8f823d964c"
}

resource "azurerm_role_assignment" "gha_uat_vm_runcommand" {
  scope                = azurerm_linux_virtual_machine.uat.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azuread_service_principal.gha_deploy_uat.object_id
}

resource "azurerm_role_assignment" "gha_uat_kv_secrets_user" {
  scope                = azurerm_key_vault.uat.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.gha_deploy_uat.object_id
}

output "vm_identity_client_id" { value = azurerm_user_assigned_identity.vm.client_id }
