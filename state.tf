terraform {
  backend "azurerm" {}

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.109.0"
    }
  }
}
