terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-documind-static-website"
  location = "East US"
}

# Create a storage account for static website hosting
resource "azurerm_storage_account" "main" {
  name                     = "stdocumind${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  static_website {
    index_document     = "login.html"
    error_404_document = "login.html"
  }

  tags = {
    environment = "production"
    project     = "DocuMind"
  }
}

# Generate a random suffix for unique storage account name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Upload the login HTML file to the $web container
resource "azurerm_storage_blob" "login" {
  name                   = "login.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "${path.module}/login.html"
}

# Upload the admin portal HTML file to the $web container
resource "azurerm_storage_blob" "admin" {
  name                   = "admin.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "${path.module}/admin.html"
}

# Upload the user portal HTML file to the $web container
resource "azurerm_storage_blob" "user" {
  name                   = "user.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "${path.module}/user.html"
}

# Outputs
output "static_website_url" {
  value       = azurerm_storage_account.main.primary_web_endpoint
  description = "The primary web endpoint URL for the static website"
}

output "login_page_url" {
  value       = "${azurerm_storage_account.main.primary_web_endpoint}login.html"
  description = "Direct URL to the login page"
}

output "admin_page_url" {
  value       = "${azurerm_storage_account.main.primary_web_endpoint}admin.html"
  description = "Direct URL to the admin portal"
}

output "user_page_url" {
  value       = "${azurerm_storage_account.main.primary_web_endpoint}user.html"
  description = "Direct URL to the user portal"
}

output "storage_account_name" {
  value       = azurerm_storage_account.main.name
  description = "The name of the storage account"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "The name of the resource group"
}
