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

# Used by networking.tf's AllowOperatorSSH rule — the Bastion replacement
# described there. Must be a narrow CIDR (ideally a /32), never 0.0.0.0/0.
variable "operator_ip_cidr" {
  description = "Operator's public IP, as a /32 CIDR, permitted to reach the VM's SSH port directly."
  type        = string
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
  name                = "eaisharedacr"
  resource_group_name = "eai-shared-rg"
}
