################################################
# Network Interface
################################################
resource "azurerm_cognitive_account" "this" {
  name                = "dify-openai"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "OpenAI"
  sku_name            = "S0"

  public_network_access_enabled = true
}

resource "azurerm_cognitive_deployment" "this" {
  name                 = "dify-openai"
  cognitive_account_id = azurerm_cognitive_account.this.id

  sku {
    name = "GlobalStandard"
  }

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "turbo-2024-04-09"
  }
}