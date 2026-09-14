# Required by azurerm_linux_virtual_machine's mandatory auth block — this
# key is never distributed or used for actual login. Real interactive
# access is via Bastion + the Azure AD login extension below, which is the
# genuine equivalent of AWS's IAM-based SSM Session Manager (no distributed
# credential). This key exists only because the resource's schema requires
# either a password or an SSH key at creation time; it satisfies that
# requirement without anyone needing to hold or use it.
resource "tls_private_key" "vm_unused" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "dev" {
  name                            = "eai-dev-host"
  resource_group_name             = azurerm_resource_group.dev.name
  location                        = azurerm_resource_group.dev.location
  size                            = "Standard_B2s_v2"
  admin_username                  = "azureuser"
  network_interface_ids           = [azurerm_network_interface.vm.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm_unused.public_key_openssh
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker azureuser
    mkdir -p /opt/eai
  EOF
  )
}

# Grants the Azure AD login extension's actual authorization — without
# this, the extension is installed but no one can use it to sign in.
resource "azurerm_role_assignment" "vm_admin_login" {
  scope                = azurerm_linux_virtual_machine.dev.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Installs Azure AD authentication on the VM itself — the actual mechanism
# that makes Bastion's "Connect with Azure AD" option work, and what
# removes the need for anyone to ever touch the throwaway SSH key above.
resource "azurerm_virtual_machine_extension" "aad_login" {
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.dev.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

output "vm_id" { value = azurerm_linux_virtual_machine.dev.id }
output "vm_public_ip" { value = azurerm_public_ip.vm.ip_address }
