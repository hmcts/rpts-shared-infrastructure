import {
  for_each = var.env == "demo" ? toset(["demo"]) : toset([])

  to = module.key-vault[0].azurerm_key_vault_access_policy.jenkins[0]
  id = "${module.key-vault[0].key_vault_id}/objectId/75141362-5195-42fb-83f1-69225bb5250b"
}