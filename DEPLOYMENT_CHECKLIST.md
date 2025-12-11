# Pre-Deployment Checklist

## ✅ Files Ready

- [x] `login.html` - Login page (12 KB)
- [x] `admin.html` - Admin portal (44 KB)
- [x] `user.html` - User portal (29 KB)
- [x] `main.tf` - Terraform configuration (3 KB)
- [x] `README.md` - Complete documentation
- [x] `DEPLOYMENT_SUMMARY.md` - Quick start guide

## Prerequisites to Install (If Not Already Installed)

### 1. Azure CLI
**Check if installed:**
```bash
az --version
```

**Install if needed:**
- Windows: Download from https://aka.ms/installazurecliwindows
- Mac: `brew install azure-cli`
- Linux: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

### 2. Terraform
**Check if installed:**
```bash
terraform version
```

**Install if needed:**
- Windows: Download from https://www.terraform.io/downloads
- Mac: `brew install terraform`
- Linux: 
  ```bash
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform
  ```

### 3. Azure Subscription
- Ensure you have an active Azure subscription
- Verify access: `az account show`

## Deployment Steps

### Step 1: Prepare Your Local Environment
```bash
# Navigate to the project directory
cd /path/to/your/workspace

# Verify all files are present
ls -la
# Should see: login.html, admin.html, user.html, main.tf, README.md
```

### Step 2: Login to Azure
```bash
az login
```
This opens a browser for authentication. Complete the login process.

### Step 3: Initialize Terraform
```bash
terraform init
```
Expected output: "Terraform has been successfully initialized!"

### Step 4: Review Deployment Plan
```bash
terraform plan
```
Review the resources that will be created:
- 1 Resource Group
- 1 Storage Account
- 1 Random String (for unique naming)
- 3 Storage Blobs (one for each HTML file)

### Step 5: Deploy to Azure
```bash
terraform apply
```
- Review the plan
- Type `yes` when prompted
- Wait for deployment (usually 1-2 minutes)

### Step 6: Get Your Website URLs
```bash
terraform output
```
Save these URLs - you'll need them to access your website!

## Post-Deployment Verification

### Test Each Page

1. **Login Page**
   ```bash
   terraform output login_page_url
   ```
   - Open the URL in a browser
   - Verify the login interface loads
   - Check that Tailwind CSS and icons render correctly

2. **Admin Portal**
   ```bash
   terraform output admin_page_url
   ```
   - Open the URL in a browser
   - Verify navigation works (Usage, Integrations, Users, Logs)
   - Check that dashboard elements display properly

3. **User Portal**
   ```bash
   terraform output user_page_url
   ```
   - Open the URL in a browser
   - Verify search interface loads
   - Test navigation between Search, History, and Files

## Troubleshooting

### Issue: "terraform: command not found"
**Solution:** Install Terraform (see Prerequisites above)

### Issue: "az: command not found"
**Solution:** Install Azure CLI (see Prerequisites above)

### Issue: "No valid subscription found"
**Solution:** Run `az login` and select the correct subscription

### Issue: "Storage account name is already taken"
**Solution:** The random suffix should prevent this, but if it occurs, run:
```bash
terraform destroy
terraform apply
```

### Issue: "HTML files not displaying correctly"
**Solution:** 
- Check browser console for errors
- Verify CDN resources are loading (Tailwind CSS, Lucide Icons)
- Ensure you're using HTTPS (not HTTP)

## Cleanup Instructions

### To Remove All Resources
```bash
terraform destroy
```
Type `yes` when prompted. This will:
- Delete all three HTML files from storage
- Delete the storage account
- Delete the resource group
- Remove all associated resources

**Note:** This action is irreversible!

## Cost Monitoring

### Check Current Costs
```bash
az consumption usage list --start-date 2025-12-01 --end-date 2025-12-31
```

### Set Up Budget Alerts (Optional)
1. Go to Azure Portal → Cost Management
2. Create a budget alert
3. Set threshold (e.g., $1/month)
4. Configure email notifications

## Next Steps After Deployment

1. ✅ Test all three pages thoroughly
2. ✅ Share URLs with your team
3. ⭐ Bookmark the admin and user portal URLs
4. 📝 Document any custom workflows
5. 🔒 Consider setting up custom domain with HTTPS
6. 📊 Monitor usage and costs

## Support Resources

- **Azure Documentation**: https://docs.microsoft.com/azure/storage/blobs/storage-blob-static-website
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Project README**: See `README.md` in this repository
- **Quick Start**: See `DEPLOYMENT_SUMMARY.md`

---

**Ready to deploy?** Start with Step 1 above! 🚀
