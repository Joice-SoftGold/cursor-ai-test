# DocuMind Azure Deployment - Quick Reference

## 🚀 One-Command Deployment

```bash
az login && terraform init && terraform apply -auto-approve && terraform output
```

## 📁 Project Files

| File | Size | Purpose |
|------|------|---------|
| `login.html` | 12 KB | Login page with auth UI |
| `admin.html` | 44 KB | Admin portal (AI console) |
| `user.html` | 29 KB | User portal (search & files) |
| `main.tf` | 3 KB | Infrastructure config |
| `README.md` | 6 KB | Full documentation |
| `DEPLOYMENT_SUMMARY.md` | 3 KB | Quick start guide |
| `DEPLOYMENT_CHECKLIST.md` | 5 KB | Step-by-step checklist |

## 🔗 URL Structure (After Deployment)

```
https://stdocumind[RANDOM].z13.web.core.windows.net/
├── login.html   ← Login page
├── admin.html   ← Admin portal
└── user.html    ← User portal
```

## ⚡ Essential Commands

### Deploy
```bash
terraform apply
```

### Get URLs
```bash
terraform output login_page_url
terraform output admin_page_url  
terraform output user_page_url
```

### Update Files
```bash
# After editing HTML files:
terraform apply
```

### Destroy
```bash
terraform destroy
```

## 🎯 Page Features

### login.html
- Standard user login
- Admin login
- Forgot password flow
- Clean, modern UI

### admin.html
- **Usage Tracking**: AI query statistics, charts
- **Integrations**: Connect data sources (Salesforce, SharePoint, etc.)
- **User Management**: Add/edit users, manage groups
- **Audit Logs**: Security events, user actions

### user.html
- **AI Search**: Natural language queries
- **Quick Search**: Keyword-based search
- **History**: Previous searches
- **File Organizer**: Upload & organize documents
- **Folder Chat**: Query specific folders

## 💰 Cost

**~$0.50/month** for typical usage
- Storage: $0.02/GB
- Transfer: First 5 GB free
- Transactions: Minimal

## ✅ Status Checks

### Is Azure CLI installed?
```bash
az --version
```

### Is Terraform installed?
```bash
terraform version
```

### Am I logged in to Azure?
```bash
az account show
```

### What will be deployed?
```bash
terraform plan
```

### What's currently deployed?
```bash
terraform show
```

## 🔧 Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| `terraform: command not found` | Install Terraform |
| `az: command not found` | Install Azure CLI |
| `No subscription found` | Run `az login` |
| Files not showing | Check `terraform show` |
| CSS not loading | Verify CDN access (Tailwind CSS) |

## 📊 Deployment Resources

**Created by Terraform:**
- Resource Group: `rg-documind-static-website`
- Storage Account: `stdocumind[RANDOM]`
- Location: `East US`
- Blobs: 3 (one per HTML file)

## 🔐 Security Notes

- ⚠️ All files are publicly accessible
- ✅ Uses HTTPS by default
- 🔒 For production: Consider Azure AD B2C
- 🛡️ Consider Azure Front Door for DDoS protection

## 📞 Support

**Full Documentation:** `README.md`
**Detailed Steps:** `DEPLOYMENT_CHECKLIST.md`
**Overview:** `DEPLOYMENT_SUMMARY.md`

---

**Quick Start:** Run these 4 commands:

```bash
az login
terraform init
terraform apply
terraform output
```

**Done!** 🎉
