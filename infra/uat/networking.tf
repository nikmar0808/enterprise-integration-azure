resource "azurerm_virtual_network" "uat" {
  name                = "eai-uat-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.uat.name
  virtual_network_name = azurerm_virtual_network.uat.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.uat.name
  virtual_network_name = azurerm_virtual_network.uat.name
  address_prefixes     = ["10.10.2.0/24"]

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# --- SUPERSEDED: Azure Bastion subnet ---
# See DEV's networking.tf (Section 10.1.1) for the full rationale — the
# same free-tier 3-Standard-public-IP quota applies identically here.
# Commented out and replaced by the AllowOperatorSSH rule on the app NSG
# plus `az ssh vm` (Section 10.2.6).
#
# resource "azurerm_subnet" "bastion" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.uat.name
#   virtual_network_name = azurerm_virtual_network.uat.name
#   address_prefixes     = ["10.10.3.0/26"]
# }

resource "azurerm_network_security_group" "app" {
  name                = "eai-uat-app-nsg"
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name

  security_rule {
    name                       = "AllowJavaGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Replaces Bastion's network path — see DEV's networking.tf comment
  # (Section 10.1.1) for the full rationale. var.operator_ip_cidr must be a
  # narrow range (ideally a /32) — never 0.0.0.0/0.
  security_rule {
    name                       = "AllowOperatorSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.operator_ip_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_public_ip" "vm" {
  name                = "eai-uat-host-pip"
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm" {
  name                = "eai-uat-host-nic"
  location            = azurerm_resource_group.uat.location
  resource_group_name = azurerm_resource_group.uat.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}
