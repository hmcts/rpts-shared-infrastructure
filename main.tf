provider azurerm {
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
  source              = "git@github.com:hmcts/cnp-module-key-vault?ref=master"
  product             = var.product
  env                 = var.env
  tenant_id           = var.tenant_id
  object_id           = var.jenkins_AAD_objectId
  resource_group_name = azurerm_resource_group.rg.name

  # dcd_platformengineering group object ID
  product_group_name         = "DTS RPTS"
  common_tags                = var.common_tags
  create_managed_identity    = true
}

resource "azurerm_key_vault_secret" "AZURE_APPINSIGHTS_KEY" {
  name         = "AppInsightsInstrumentationKey"
  value        = azurerm_application_insights.appinsights.instrumentation_key
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_application_insights" "appinsights" {
  name                = "${var.product}-appinsights-${var.env}"
  location            = var.appinsights_location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

  tags = var.common_tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to appinsights as otherwise upgrading to the Azure provider 2.x
      # destroys and re-creates this appinsights instance
      application_type,
    ]
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                = replace("${var.product}${var.env}", "-", "")
  resource_group_name = azurerm_resource_group.rg.name

  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  allow_blob_public_access = true

  tags = var.common_tags
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name      = "storage-account-name"
  value     = azurerm_storage_account.storage_account.name
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage_account_primary_key" {
  name      = "storage-account-primary-key"
  value     = azurerm_storage_account.storage_account.primary_access_key
  key_vault_id = module.key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage_account_connection_string" {
  name      = "storage-account-connection-string"
  value     = azurerm_storage_account.storage_account.primary_connection_string
  key_vault_id = module.key-vault.key_vault_id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_primary_key" {
  sensitive = true
  value     = azurerm_storage_account.storage_account.primary_access_key
}

resource "azurerm_key_vault_secret" "POSTGRES-USER" {
  name         = "api-POSTGRES-USER"
  value        = module.rpts-database.user_name
  key_vault_id = data.azurerm_key_vault.rpts_key_vault.id
}

resource "azurerm_key_vault_secret" "POSTGRES-PASS" {
  name         = "api-POSTGRES-PASS"
  value        = module.rpts-database.postgresql_password
  key_vault_id = data.azurerm_key_vault.rpts_key_vault.id
}

resource "azurerm_key_vault_secret" "POSTGRES_HOST" {
  name         = "api-POSTGRES-HOST"
  value        = module.rpts-database.host_name
  key_vault_id = data.azurerm_key_vault.rpts_key_vault.id
}

resource "azurerm_key_vault_secret" "POSTGRES_PORT" {
  name         = "api-POSTGRES-PORT"
  value        = module.rpts-database.postgresql_listen_port
  key_vault_id = data.azurerm_key_vault.rpts_key_vault.id
}

resource "azurerm_key_vault_secret" "POSTGRES_DATABASE" {
  name         = "api-POSTGRES-DATABASE"
  value        = module.rpts-database.postgresql_database
  key_vault_id = data.azurerm_key_vault.rpts_key_vault.id
}

module "rpts-database" {
  source             = "git@github.com:hmcts/cnp-module-postgres?ref=master"
  product            = var.product
  location           = var.location
  env                = var.env
  postgresql_user    = "rpts"
  database_name      = "rpts"
  postgresql_version = "11"
  sku_name           = "GP_Gen5_2"
  sku_tier           = "GeneralPurpose"
  storage_mb         = "51200"
  common_tags        = var.common_tags
  subscription       = var.subscription
}
