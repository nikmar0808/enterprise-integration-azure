terraform {
  required_providers {
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
  required_version = ">= 1.5.0"
}

provider "azuread" {}
provider "azurerm" {
  features {}
  subscription_id = "39d5c2a5-e03f-48dd-b4cd-955fdcee2cb0"
  tenant_id       = "0cf62dc3-5a55-48b7-b426-0d69e11b64aa"
}

# --- GitHub Actions deployment identities ---
# THREE separate Entra applications — one per environment — not one
# application with three federated credentials. RBAC in Entra is scoped to
# the service principal, not to which federated credential authenticated
# it; a single shared application would mean any RBAC grant made to it
# (Section 10) is usable regardless of which environment's GitHub context
# obtained the token, defeating the per-environment isolation Section 1
# Rule 4 requires. This matches AWS's three separate IAM roles exactly —
# separate principal per environment, not separate trust condition on one
# shared principal.

resource "azuread_application" "gha_deploy_dev" {
  display_name = "gha-deploy-dev-identity"
}
resource "azuread_service_principal" "gha_deploy_dev" {
  client_id = azuread_application.gha_deploy_dev.client_id
}
resource "azuread_application_federated_identity_credential" "gha_deploy_dev_ref" {
  application_id = azuread_application.gha_deploy_dev.id
  display_name   = "github-actions-dev-ref"
  description    = "GitHub Actions OIDC — dev build/push jobs (no environment: key, push-triggered on develop)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:nikmar0808@217144230/enterprise-integration-azure@1366899366:ref:refs/heads/develop"
}

# A second, separate credential — Entra federated credentials match exactly
# one subject each (unlike AWS IAM's StringLike, which accepts an array).
# The docker-build-push jobs (no `environment:` key) receive a
# ref:refs/heads/BRANCH-shaped claim and authenticate via the credential
# above; the deploy-dev job declares `environment: dev` and receives an
# environment:NAME-shaped claim instead, regardless of branch — it needs
# this second credential or it fails OIDC even though the build jobs work.
resource "azuread_application_federated_identity_credential" "gha_deploy_dev" {
  application_id = azuread_application.gha_deploy_dev.id
  display_name   = "github-actions-dev-environment"
  description    = "GitHub Actions OIDC — deploy-dev job (declares environment: dev)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:nikmar0808@217144230/enterprise-integration-azure@1366899366:environment:dev"
}

resource "azuread_application" "gha_deploy_uat" {
  display_name = "gha-deploy-uat-identity"
}
resource "azuread_service_principal" "gha_deploy_uat" {
  client_id = azuread_application.gha_deploy_uat.client_id
}
resource "azuread_application_federated_identity_credential" "gha_deploy_uat" {
  application_id = azuread_application.gha_deploy_uat.id
  display_name   = "github-actions-uat"
  description    = "GitHub Actions OIDC — uat environment deployments"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  # A workflow_dispatch-triggered job declaring `environment: uat` receives
  # this claim shape, not a ref:refs/heads/BRANCH shape.
  subject        = "repo:nikmar0808@217144230/enterprise-integration-azure@1366899366:environment:uat"
}

resource "azuread_application" "gha_deploy_prod" {
  display_name = "gha-deploy-prod-identity"
}
resource "azuread_service_principal" "gha_deploy_prod" {
  client_id = azuread_application.gha_deploy_prod.client_id
}
resource "azuread_application_federated_identity_credential" "gha_deploy_prod" {
  application_id = azuread_application.gha_deploy_prod.id
  display_name   = "github-actions-prod"
  description    = "GitHub Actions OIDC — prod environment deployments"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:nikmar0808@217144230/enterprise-integration-azure@1366899366:environment:prod"
}

# --- HCP Terraform identity ---
# One identity, wildcarded across all workspaces. This one legitimately
# stays shared: it authenticates Terraform runs, and workspace-level state
# isolation (Section 8) — not this trust condition — is what separates one
# environment's infrastructure from another's. There is no RBAC granted to
# it at all under Local execution mode (Section 8), so the single-principal
# concern above does not apply here.

resource "azuread_application" "tfc_run" {
  display_name = "tfc-run-identity"
}

resource "azuread_service_principal" "tfc_run" {
  client_id = azuread_application.tfc_run.client_id
}

resource "azuread_application_federated_identity_credential" "tfc_run" {
  application_id = azuread_application.tfc_run.id
  display_name   = "hcp-terraform-workload-identity"
  description    = "HCP Terraform OIDC — plan/apply runs across all three workspaces"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://app.terraform.io"
  subject        = "organization:MyOtg:project:*:workspace:eai-*-azure:run_phase:*"
}

# No RBAC role assignments are created here — that happens once each
# environment's resource group exists (Section 10), which is exactly the
# circularity this bootstrap step exists to break.

output "gha_deploy_dev_client_id"  { value = azuread_application.gha_deploy_dev.client_id }
output "gha_deploy_uat_client_id"  { value = azuread_application.gha_deploy_uat.client_id }
output "gha_deploy_prod_client_id" { value = azuread_application.gha_deploy_prod.client_id }
output "tfc_run_client_id"         { value = azuread_application.tfc_run.client_id }