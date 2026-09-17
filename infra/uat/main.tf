terraform {
  cloud {
    organization = "MyOtg"
    workspaces {
      name = "eai-uat-azure"
    }
  }
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "uat" {
  name     = "eai-uat-rg"
  location = "centralindia"
  tags     = { Project = "enterprise-integration", Environment = "uat", ManagedBy = "terraform" }
}

# The shared ACR (Section 9) lives in a different Terraform Cloud workspace
# and therefore a different state file — referenced here by data source
# rather than a resource, since this workspace does not manage it.
data "azurerm_container_registry" "shared" {
  name                = var.acr_name
  resource_group_name = "eai-shared-rg"
}
