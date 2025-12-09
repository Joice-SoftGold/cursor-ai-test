# DocuMind - Quick Start Guide

**🚀 Deploy DocuMind in 10 Minutes**

---

## Prerequisites
- ✅ Azure Ubuntu VM with public IP
- ✅ SSH access to the server
- ✅ Ports 22, 80 open in Azure NSG

---

## Step-by-Step Deployment

### 1️⃣ SSH into Server
```bash
ssh azureuser@YOUR_VM_IP
```

### 2️⃣ Install Nginx
```bash
sudo apt update && sudo apt install nginx -y
```

### 3️⃣ Create Directory
```bash
sudo mkdir -p /var/www/documind && cd /var/www/documind
```

### 4️⃣ Create Files
Create these 3 files using `nano`:

```bash
# File 1: Login Page
sudo nano index.html
# Paste content from "Documind Login page v0.2.txt" (USE FIXED VERSION!)
# Save: Ctrl+X → Y → Enter

# File 2: Admin Portal
sudo nano admin.html
# Paste content from "Admin portal v0.2.txt"
# Save: Ctrl+X → Y → Enter

# File 3: User Portal
sudo nano user.html
# Paste content from "Standard user v0.1.txt"
# Save: Ctrl+X → Y → Enter
```

### 5️⃣ Set Permissions
```bash
sudo chown -R www-data:www-data /var/www/documind
sudo chmod -R 755 /var/www/documind
```

### 6️⃣ Configure Nginx
```bash
sudo tee /etc/nginx/sites-available/documind << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/documind;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

### 7️⃣ Open Browser
```
http://YOUR_VM_IP
```

**You're done!** 🎉

---

## ⚠️ IMPORTANT: Use Fixed index.html

The original "Documind Login page v0.2.txt" has a bug - login doesn't redirect!

**Use this fixed login handler in your index.html:**

Find this section around line 170:
```javascript
document.getElementById('login-form').addEventListener('submit', function(e) {
    e.preventDefault();
    const btn = document.getElementById('login-btn');
    const loginType = document.getElementById('login-type').value;  // ← MUST HAVE THIS
    
    btn.disabled = true;
    btn.innerHTML = '<i data-lucide="loader-2" class="animate-spin w-5 h-5 mr-2 inline"></i> Authenticating...';
    lucide.createIcons();
    
    setTimeout(() => {
        // ← MUST HAVE THIS REDIRECT LOGIC
        if (loginType === 'admin') {
            window.location.href = '/admin.html';
        } else {
            window.location.href = '/user.html';
        }
    }, 1500);
});
```

---

## ✅ Testing Checklist

- [ ] Login page loads: `http://YOUR_VM_IP`
- [ ] Admin login redirects to `/admin.html`
- [ ] User login redirects to `/user.html`
- [ ] Both land on "Search & Query" page
- [ ] No JavaScript errors in browser console

---

## 🆘 Quick Troubleshooting

**Problem:** Can't access website
```bash
sudo systemctl status nginx
sudo netstat -tlnp | grep :80
# Check Azure NSG port 80 is open
```

**Problem:** Login doesn't redirect
```bash
# You have the old broken index.html
# Apply the bug fix (see BUG_FIX_OLD_VS_NEW.md)
```

**Problem:** 404 errors
```bash
ls -lh /var/www/documind/
# Should show 3 files: index.html, admin.html, user.html
```

---

## 📚 Full Documentation

- **COMPLETE_DEPLOYMENT_DOCUMENTATION.md** - Detailed step-by-step guide
- **BUG_FIX_OLD_VS_NEW.md** - Code comparison and bug fix details
- **This file** - Quick reference

---

**Deployed on:** December 9, 2025  
**Server:** 4.242.19.202  
**Status:** ✅ WORKING
