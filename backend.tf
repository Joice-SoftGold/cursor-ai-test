# Configuration for Terraform Remote State Backend on Azure Storage

terraform {
  backend "azurerm" {
    resource_group_name  = "deployaks-tfstate-RG"
    storage_account_name = "deployaksstorage"
    container_name       = "tfstate"
    key                  = "aks/production-aks.tfstate"
  }
}
