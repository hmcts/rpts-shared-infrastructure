provider "azurerm" {
  features {}
}

locals {
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.product}-${var.env}"
  location = var.location

  tags = var.common_tags
}

module "key-vault" {
  count = contains(["aat", "demo", "prod"], var.env) ? 1 : 0

  source              = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  product             = var.product
  env                 = var.env
  tenant_id           = var.tenant_id
  object_id           = var.jenkins_AAD_objectId
  resource_group_name = azurerm_resource_group.rg.name

  # dcd_platformengineering group object ID
  product_group_name      = "DTS RPTS"
  common_tags             = var.common_tags
  create_managed_identity = true
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY" {
  count        = contains(["aat", "demo", "prod"], var.env) ? 1 : 0
  name         = "AppInsightsInstrumentationKey"
  value        = module.application_insights[0].instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
}

module "application_insights" {
  count = contains(["aat", "demo", "prod"], var.env) ? 1 : 0

  source = "git@github.com:hmcts/terraform-module-application-insights?ref=4.x"

  env      = var.env
  product  = var.product
  name     = "${var.product}-appinsights"
  location = var.location

  resource_group_name = azurerm_resource_group.rg.name

  common_tags = var.common_tags
}
moved {
  from = azurerm_application_insights.appinsights
  to   = module.application_insights[0].azurerm_application_insights.this
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  count        = contains(["aat", "demo", "prod"], var.env) ? 1 : 0
  name         = "app-insights-connection-string"
  value        = module.application_insights[0].connection_string
  key_vault_id = module.key-vault.key_vault_id
}