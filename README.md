# DocuMind Static Website - Azure Deployment

This repository contains the infrastructure code to host the DocuMind static website on Azure Storage Static Website hosting.

## Architecture

- **Azure Storage Account** with Static Website feature enabled
- **Static HTML files** hosted in the `$web` container
- **Cost-effective** solution for hosting static content

## Files

- `login.html` - DocuMind login page with authentication UI
- `admin.html` - Admin portal with AI usage tracking, integrations, user management, and audit logs
- `user.html` - User portal with AI search, query interface, and file organizer
- `main.tf` - Terraform infrastructure configuration

## Prerequisites

1. **Azure Account** - You need an active Azure subscription
2. **Azure CLI** - Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
3. **Terraform** - Install from https://www.terraform.io/downloads

## Deployment Instructions

### Step 1: Login to Azure

```bash
az login
```

This will open a browser window for authentication.

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Review the Deployment Plan

```bash
terraform plan
```

### Step 4: Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### Step 5: Get the Website URLs

After deployment completes, Terraform will output all the URLs:

```bash
terraform output
```

You will see:
- **Login Page**: `https://stdocumind<random>.z13.web.core.windows.net/login.html`
- **Admin Portal**: `https://stdocumind<random>.z13.web.core.windows.net/admin.html`
- **User Portal**: `https://stdocumind<random>.z13.web.core.windows.net/user.html`

You can also get individual URLs:

```bash
terraform output login_page_url
terraform output admin_page_url
terraform output user_page_url
```

## Manual Upload (Alternative Method)

If you prefer to manually upload files without using Terraform:

### Step 1: Create Storage Account via Azure Portal

1. Go to Azure Portal (https://portal.azure.com)
2. Click "Create a resource" → "Storage account"
3. Fill in the details:
   - Resource group: Create new or select existing
   - Storage account name: Must be globally unique (e.g., `stdocumindwebsite`)
   - Region: Choose your preferred location
   - Performance: Standard
   - Redundancy: LRS (Locally-redundant storage)
4. Click "Review + create" → "Create"

### Step 2: Enable Static Website

1. Go to your storage account
2. In the left menu, under "Data management", click "Static website"
3. Click "Enabled"
4. Set "Index document name" to `login.html`
5. Set "Error document path" to `login.html`
6. Click "Save"
7. Note the "Primary endpoint" URL - this is your website URL

### Step 3: Upload HTML Files

1. In your storage account, go to "Containers"
2. Click on the "$web" container (automatically created when you enabled static website)
3. Click "Upload"
4. Select all three HTML files (`login.html`, `admin.html`, `user.html`)
5. Click "Upload"

### Step 4: Access Your Website

Navigate to the primary endpoint URL from Step 2 and add the page name:
- Login: `<primary-endpoint>/login.html`
- Admin: `<primary-endpoint>/admin.html`
- User: `<primary-endpoint>/user.html`

## Cost Estimate

Azure Storage Static Website hosting is very cost-effective:
- Storage: ~$0.02 per GB per month
- Data transfer: First 5 GB free, then ~$0.087 per GB
- Transactions: Minimal cost for static content

**Estimated cost for this project: Less than $1/month** for typical low-traffic usage.

## Adding More Files

### Using Terraform

1. Add the new HTML file to the workspace
2. Add a new `azurerm_storage_blob` resource in `main.tf`:

```hcl
resource "azurerm_storage_blob" "file2" {
  name                   = "file2.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "${path.module}/file2.html"
}
```

3. Run `terraform apply` to upload the new file

### Manual Upload

Simply upload additional files to the `$web` container via Azure Portal or Azure CLI:

```bash
az storage blob upload \
  --account-name <your-storage-account-name> \
  --container-name '$web' \
  --name file2.html \
  --file ./file2.html \
  --content-type "text/html"
```

## Code Requirements

**Good news!** Your HTML files don't need any modifications to work with Azure Storage Static Website hosting. The code uses:
- CDN-hosted libraries (Tailwind CSS, Lucide Icons)
- Client-side JavaScript
- No server-side dependencies

Everything will work exactly as-is on Azure Storage!

## Custom Domain (Optional)

To use a custom domain like `login.documind.com`:

1. Go to your storage account → "Custom domain"
2. Follow the instructions to add a CNAME record in your DNS provider
3. Or use Azure CDN for HTTPS support with custom domains

## Security Notes

- Static websites on Azure Storage are **publicly accessible**
- All files in the `$web` container are readable by anyone with the URL
- For production use, consider:
  - Azure CDN with custom domain and HTTPS
  - Azure Front Door for additional security features
  - Authentication through Azure AD B2C (requires backend integration)

## Cleanup

To remove all resources and avoid charges:

```bash
terraform destroy
```

Or manually delete the resource group from Azure Portal.

## Next Steps

1. **Run the deployment** using the instructions above
2. **Test all three pages** at the provided URLs:
   - Login page: Entry point for user authentication
   - Admin portal: Management interface with usage tracking and user management
   - User portal: Standard user interface with AI search and file organization
3. **Optional**: Set up a custom domain

## Support

If you encounter any issues during deployment:
- Ensure you're logged into Azure CLI: `az account show`
- Check that your Azure subscription has available quota
- Verify Terraform is properly installed: `terraform version`

---

**Current Status**: ✅ Ready for deployment! All three HTML files are configured and ready to be hosted on Azure.
