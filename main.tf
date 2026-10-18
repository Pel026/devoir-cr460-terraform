# ---------- Point 7 : groupe de ressources ----------
resource "azurerm_resource_group" "rg" {
  name     = "rg-cr460"
  location = "canadacentral"
}

# ---------- Point 8 : réseau virtuel et sous-réseau ----------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-cr460"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-cr460"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ---------- Point 9 : machine virtuelle (en pause : quota insuffisant) ----------
resource "random_password" "vm_password" {
  length           = 20
  special          = true
  override_special = "!#%*-_"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-cr460"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# resource "azurerm_linux_virtual_machine" "vm" {
#   name                            = "vm-cr460"
#   location                        = azurerm_resource_group.rg.location
#   resource_group_name             = azurerm_resource_group.rg.name
#   size                            = "Standard_B2s"
#   admin_username                  = "azureadmin"
#   admin_password                  = random_password.vm_password.result
#   disable_password_authentication = false
#   network_interface_ids           = [azurerm_network_interface.nic.id]
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
  name                = "aci-cr460"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "cr460-CHANGE-MOI"

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