#!/bin/bash

# DocuMind Azure Deployment Script
# This script automates the deployment of DocuMind to Azure Static Website

set -e  # Exit on error

echo "=================================================="
echo "  DocuMind - Azure Static Website Deployment"
echo "=================================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed.${NC}"
    echo "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed.${NC}"
    echo "Please install it from: https://www.terraform.io/downloads"
    exit 1
fi

# Check if user is logged in to Azure
echo "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please log in:${NC}"
    az login
else
    ACCOUNT=$(az account show --query name -o tsv)
    echo -e "${GREEN}✓ Logged in to Azure${NC}"
    echo "  Active subscription: $ACCOUNT"
fi

echo ""
echo "=================================================="
echo "  Step 1: Checking Required Files"
echo "=================================================="

REQUIRED_FILES=("index.html" "login.html" "admin.html" "user.html" "main.tf")
MISSING_FILES=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file - MISSING"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo -e "${RED}Error: $MISSING_FILES required file(s) missing.${NC}"
    exit 1
fi

echo ""
echo "=================================================="
echo "  Step 2: Initializing Terraform"
echo "=================================================="

terraform init

echo ""
echo "=================================================="
echo "  Step 3: Terraform Plan"
echo "=================================================="

terraform plan -out=tfplan

echo ""
echo "=================================================="
echo "  Step 4: Deploy to Azure"
echo "=================================================="
echo ""
echo -e "${YELLOW}This will create Azure resources and may incur costs.${NC}"
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

terraform apply tfplan

echo ""
echo "=================================================="
echo "  Deployment Complete!"
echo "=================================================="
echo ""

# Get the website URL
WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")

if [ -n "$WEBSITE_URL" ]; then
    echo -e "${GREEN}✓ Your DocuMind application is now live!${NC}"
    echo ""
    echo "  Website URL: ${GREEN}${WEBSITE_URL}${NC}"
    echo ""
    echo "  Login Page:  ${WEBSITE_URL}login.html"
    echo "  Admin Portal: ${WEBSITE_URL}admin.html"
    echo "  User Portal:  ${WEBSITE_URL}user.html"
    echo ""
    echo "Default credentials (demo):"
    echo "  Email: demo@documind.ai"
    echo "  Password: password"
else
    echo -e "${YELLOW}Could not retrieve website URL. Check Terraform outputs:${NC}"
    terraform output
fi

echo ""
echo "=================================================="
echo "  Next Steps"
echo "=================================================="
echo ""
echo "1. Visit the website URL above"
echo "2. Login as Admin or Standard User"
echo "3. Both roles land on Search & Query page by default"
echo ""
echo "To update files later, modify HTML and run:"
echo "  terraform apply"
echo ""
echo "To destroy all resources:"
echo "  terraform destroy"
echo ""
