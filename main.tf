# main

terraform {

  required_version = ">=1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.35.0"
    }
  }
  #The backend below works because we are authenticated via the az login
  backend "azurerm" {
    resource_group_name  = "watsont-sandbox-rg"
    storage_account_name = "watsontsandboxstorage"
    container_name       = "watsont-sandbox-terraform-be"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "config" {
}

locals {
  vms = {
    vm1 = azurerm_linux_virtual_machine.vm1.id
    vm2 = azurerm_linux_virtual_machine.vm2.id
  }
}

################################################
## virtual machines, vnet, subnet for testing ##
################################################

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.rg
  tags                = var.tags
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "subnet_module" {
  source         = "./modules/subnet"
  resource_group = var.rg
  vnet_name      = azurerm_virtual_network.example.name
}

resource "azurerm_network_security_group" "example" {
  name                = "NSG1"
  location            = var.location
  resource_group_name = var.rg

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }

  tags = var.tags
}
resource "azurerm_network_interface_security_group_association" "sg_assoc1" {
  network_interface_id      = azurerm_network_interface.example1.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_network_interface_security_group_association" "sg_assoc2" {
  network_interface_id      = azurerm_network_interface.example2.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_subnet_network_security_group_association" "sg_assoc_subnet" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}
resource "azurerm_public_ip" "pip_vm1" {
  name = "pipvm1"

  resource_group_name = var.rg
  location            = var.location

  allocation_method = "Static"
  sku               = "Standard"
  tags              = var.tags

  lifecycle {
    ignore_changes = [
      zones
    ]
  }
}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = var.location
  resource_group_name = var.rg
  tags                = var.tags

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.20"
    public_ip_address_id          = azurerm_public_ip.pip_vm1.id
  }
}

resource "azurerm_public_ip" "pip_vm2" {
  name = "pipvm2"

  resource_group_name = var.rg
  location            = var.location

  allocation_method = "Static"
  sku               = "Standard"
  tags              = var.tags

  lifecycle {
    ignore_changes = [
      zones
    ]
  }
}

resource "azurerm_network_interface" "example2" {
  name                = "nic2"
  location            = var.location
  resource_group_name = var.rg
  tags                = var.tags

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.22"
    public_ip_address_id          = azurerm_public_ip.pip_vm2.id
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = "vm1"
  resource_group_name             = var.rg
  location                        = var.location
  size                            = "Standard_B1ls"
  disable_password_authentication = false
  admin_username                  = var.user
  admin_password                  = var.pword
  tags                            = var.tags
  network_interface_ids = [
    azurerm_network_interface.example1.id,
  ]



  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                            = "vm2"
  resource_group_name             = var.rg
  location                        = var.location
  size                            = "Standard_B1ls"
  disable_password_authentication = false
  admin_username                  = var.user
  admin_password                  = var.pword
  tags                            = var.tags
  network_interface_ids = [
    azurerm_network_interface.example2.id,
  ]



  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}