variable "environment" {
  type        = string
  description = "The environment we deploy into"
  default     = "sbox"
}

variable "location" {
  type        = string
  description = "The Azure region we deploy into"
  default     = "UK South"
}

variable "rg" {
  type        = string
  description = "The Azure resource group we deploy into"
  default     = "watsont-sandbox-rg"
}

variable "user" {
  type = string
}

variable "pword" {
  type = string
}

variable "vm" {
  type        = list(string)
  description = "A List of the VMs we will create"
  default     = ["vm1", "vm2"]
}

variable "tags" {
  type = map(string)
  default = {
    Owner    = "watsont"
    Reason   = "test"
    Lifespan = "temporary"
    Project  = "watsont-rg-test"
  }
}

variable "nsg_rules" {
  description = "The values for each NSG rule."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
}