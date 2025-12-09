# DocuMind - Azure Static Website Hosting

This repository contains the DocuMind application files configured for hosting on Azure Storage Static Website.

## Overview

DocuMind is an Enterprise AI Search & Indexing Platform with:
- **Login Page** (`login.html`) - Entry point with admin/user selection
- **Admin Portal** (`admin.html`) - Full admin console with user management, audit logs, integrations, and file management
- **User Portal** (`user.html`) - Standard user interface for search, query, and file upload

## Architecture

The application uses:
- Azure Storage Account with Static Website hosting enabled
- Three main HTML files (login, admin, user portals)
- External CDN resources (Tailwind CSS, Lucide Icons)
- Client-side JavaScript (no backend required for demo)

## Login Flow

When users visit the site, they:
1. Land on `index.html` which redirects to `login.html`
2. Select "Admin" or "Standard User" login type
3. After authentication, they're redirected to:
   - **Admin users** → `admin.html` (Search & Query page by default)
   - **Standard users** → `user.html` (Search & Query page by default)

Both portals open directly to the **Search & Query** page as requested.

## Files Structure

```
/workspace/
├── index.html          # Redirect to login
├── login.html          # Login page with role selection
├── admin.html          # Admin portal (from "Admin portal v0.2.txt")
├── user.html           # User portal (from "Standard user v0.1.txt")
├── main.tf             # Terraform infrastructure
├── deploy.sh           # Deployment script
└── README.md           # This file
```

## Deployment Instructions

### Prerequisites

1. **Azure CLI** installed and authenticated
   ```bash
   az login
   ```

2. **Terraform** installed (version 1.0+)
   ```bash
   terraform version
   ```

3. **Azure Subscription** with permissions to create resources

### Step 1: Initialize Terraform

```bash
terraform init
```

### Step 2: Review the Plan

```bash
terraform plan
```

This will show you:
- Resource Group to be created
- Storage Account configuration
- Files to be uploaded

### Step 3: Deploy to Azure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### Step 4: Get Your Website URL

After successful deployment, Terraform will output:
```
website_url = "https://documindstatic.z13.web.core.windows.net/"
```

Visit this URL to access your DocuMind application!

## Alternative: Manual Deployment

If you prefer not to use Terraform, you can deploy manually:

### Option A: Using Azure Portal

1. Create a Storage Account
   - Account kind: **StorageV2**
   - Replication: **LRS**
   - Performance: **Standard**

2. Enable Static Website
   - Go to: **Settings → Static website**
   - Enable: **Enabled**
   - Index document: `index.html`
   - Error document: `404.html`

3. Upload Files
   - Go to: **Data storage → Containers → $web**
   - Upload: `index.html`, `login.html`, `admin.html`, `user.html`

### Option B: Using Azure CLI

```bash
# Set variables
RG_NAME="documind-rg"
LOCATION="eastus"
STORAGE_NAME="documindstatic"  # Must be globally unique

# Create resource group
az group create --name $RG_NAME --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

# Enable static website
az storage blob service-properties update \
  --account-name $STORAGE_NAME \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# Upload files
az storage blob upload-batch \
  --account-name $STORAGE_NAME \
  --destination '$web' \
  --source . \
  --pattern "*.html"

# Get the website URL
az storage account show \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --query "primaryEndpoints.web" \
  --output tsv
```

## Customization

### Changing Storage Account Name

The storage account name must be globally unique. To change it:

1. Edit `main.tf`:
   ```hcl
   variable "storage_account_name" {
     default = "your-unique-name-here"  # 3-24 chars, lowercase, no special chars
   }
   ```

2. Re-run `terraform apply`

### Changing Azure Region

To deploy to a different region:

1. Edit `main.tf`:
   ```hcl
   variable "location" {
     default = "West Europe"  # or your preferred region
   }
   ```

2. Re-run `terraform apply`

## Features

### Admin Portal Features
- ✅ AI Search & Query Console (Default landing page)
- ✅ Upload & Queue Management
- ✅ Data Source Integrations
- ✅ User Management
- ✅ Audit Logs with filtering

### User Portal Features  
- ✅ AI Search & Query Console (Default landing page)
- ✅ Session History
- ✅ Upload & Queue
- ✅ Limited permissions (no admin functions)

## Security Notes

⚠️ **Important**: This is a static demo application with:
- No real authentication backend
- Client-side only validation
- Mock data for demonstration

For production use, you should:
1. Implement proper authentication (Azure AD, OAuth, etc.)
2. Add a backend API for data operations
3. Secure sensitive endpoints
4. Implement proper session management
5. Add HTTPS custom domain

## Troubleshooting

### Storage account name already exists
The storage account name must be globally unique across Azure. Change the `storage_account_name` variable in `main.tf`.

### Files not updating
After modifying HTML files, run:
```bash
terraform apply -replace="azurerm_storage_blob.admin" -replace="azurerm_storage_blob.user"
```

### Can't access website
1. Check the URL is using `https://` (not `http://`)
2. Verify static website is enabled in Storage Account settings
3. Ensure files are in the `$web` container
4. Clear browser cache

## Cleanup

To delete all Azure resources:

```bash
terraform destroy
```

Type `yes` to confirm deletion.

## Support

For issues or questions about:
- **Azure deployment**: Check [Azure Storage Static Website docs](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
- **Terraform**: See [Terraform Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## License

© 2025 Cyber Base Limited. All rights reserved.
