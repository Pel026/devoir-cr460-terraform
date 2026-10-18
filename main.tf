data "azurerm_client_config" "current" {}

locals {
  common_tags = {
    Projet = var.project_tag
  }
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# ---------- Point 7 : groupe de ressources ----------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}"
  location = var.location
  tags     = local.common_tags
}

# ---------- Point 8 : réseau virtuel et sous-réseau ----------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-${var.prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ---------- Point 12 : Key Vault et secret ----------
resource "random_password" "vm_password" {
  length           = 20
  special          = true
  override_special = "!#%*-_"
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.prefix}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.common_tags

  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }
}

resource "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.kv.id
  tags         = local.common_tags
}

# ---------- Point 9 : VM (en pause : quota insuffisant) ----------
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# resource "azurerm_linux_virtual_machine" "vm" {
#   name                            = "vm-${var.prefix}"
#   location                        = azurerm_resource_group.rg.location
#   resource_group_name             = azurerm_resource_group.rg.name
#   size                            = var.vm_size
#   admin_username                  = var.admin_username
#   admin_password                  = azurerm_key_vault_secret.vm_password.value
#   disable_password_authentication = false
#   network_interface_ids           = [azurerm_network_interface.nic.id]
#   tags                            = local.common_tags
#
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "ubuntu-24_04-lts"
#     sku       = "server"
#     version   = "latest"
#   }
# }

# ---------- Point 10 : container Docker ----------
resource "azurerm_container_group" "app" {
  name                = "aci-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-${random_string.suffix.result}"
  tags                = local.common_tags

  container {
    name   = "web"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}