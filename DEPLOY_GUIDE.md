# 🚀 DocuMind - Deploy to Azure Ubuntu Server

## What You Have

✅ **index.html** - Redirects to login  
✅ **login.html** - Login page with admin/user toggle  
✅ **Scripts** - Helper scripts for deployment

## What You Need to Do

### Step 1: Create the Portal HTML Files

You provided the content in text files. Create the HTML files:

**admin.html** - Copy content from "Admin portal v0.2.txt"  
**user.html** - Copy content from "Standard user v0.1.txt"

**Quick method:**
```bash
# If text files are in same directory:
cp "Admin portal v0.2.txt" admin.html
cp "Standard user v0.1.txt" user.html

# OR use the helper script:
./create_html_files.sh
```

---

## Deploy to Your Azure Ubuntu Server

### Prerequisites

- Azure Ubuntu VM running
- SSH key file (`.pem` or `.key`)
- VM's public IP address

### Step-by-Step Deployment

#### 1. **Fix SSH Key Permissions** (Your Machine)

```bash
chmod 400 ~/path/to/your-azure-key.pem
```

**Why?** SSH requires the key file to have restricted permissions (read-only for owner).

#### 2. **Connect to Your Server**

```bash
ssh -i ~/path/to/your-azure-key.pem azureuser@YOUR_SERVER_IP
```

Replace:
- `~/path/to/your-azure-key.pem` → your actual key path
- `YOUR_SERVER_IP` → your VM's public IP from Azure Portal
- `azureuser` → your VM username

#### 3. **Install Nginx** (On Server)

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 4. **Configure Firewall** (On Server)

```bash
# Ubuntu firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp  
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

**Also in Azure Portal:**
- Go to your VM → **Networking** → **Network Security Group**
- Click **Add inbound port rule**
- Port: **80**, Protocol: **TCP**, Action: **Allow**
- Click **Add**

#### 5. **Setup Web Directory** (On Server)

```bash
sudo mkdir -p /var/www/documind
sudo chown -R $USER:$USER /var/www/documind
sudo chmod -R 755 /var/www/documind
```

#### 6. **Configure Nginx** (On Server)

```bash
sudo nano /etc/nginx/sites-available/documind
```

Paste this configuration (replace YOUR_SERVER_IP with actual IP):

```nginx
server {
    listen 80;
    listen [::]:80;
    
    server_name YOUR_SERVER_IP;
    
    root /var/www/documind;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    gzip on;
    gzip_types text/html text/css application/javascript;
}
```

Save: **Ctrl+O**, **Enter**  
Exit: **Ctrl+X**

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

#### 7. **Upload Files** (From Your Machine)

**Option A - Use upload script:**
```bash
./upload.sh
```

**Option B - Manual upload:**
```bash
scp -i ~/path/to/your-azure-key.pem \
    index.html login.html admin.html user.html \
    azureuser@YOUR_SERVER_IP:/tmp/
```

Then SSH back into server and move files:
```bash
ssh -i ~/path/to/your-azure-key.pem azureuser@YOUR_SERVER_IP
sudo mv /tmp/*.html /var/www/documind/
sudo chown -R www-data:www-data /var/www/documind/
sudo chmod -R 755 /var/www/documind/
exit
```

#### 8. **Test Your Website**

Open browser:
```
http://YOUR_SERVER_IP
```

You should see DocuMind login page! 🎉

---

## Login Flow

1. User visits `http://YOUR_SERVER_IP`
2. Redirects to `login.html`
3. User selects **Admin** or **Standard User**
4. After login:
   - **Admin** → `admin.html` (lands on Search & Query page)
   - **Standard User** → `user.html` (lands on Search & Query page)

**Demo credentials:**
- Email: demo@documind.ai
- Password: password

---

## Quick Commands Cheat Sheet

```bash
# Fix SSH key
chmod 400 ~/path/to/key.pem

# Connect to server
ssh -i ~/path/to/key.pem azureuser@SERVER_IP

# Upload files
scp -i ~/path/to/key.pem *.html azureuser@SERVER_IP:/tmp/

# Check Nginx status
sudo systemctl status nginx

# View logs
sudo tail -f /var/log/nginx/access.log

# Restart Nginx
sudo systemctl restart nginx

# Test Nginx config
sudo nginx -t
```

---

## Troubleshooting

### ❌ "Permission denied (publickey)"

**Fix:**
```bash
chmod 400 ~/path/to/your-key.pem
```

### ❌ Can't access website

**Check 1 - Nginx running:**
```bash
sudo systemctl status nginx
```

**Check 2 - Files in place:**
```bash
ls -la /var/www/documind/
```

**Check 3 - Azure NSG:**
- Azure Portal → VM → Networking
- Port 80 must be **open** for inbound

**Check 4 - Ubuntu firewall:**
```bash
sudo ufw status
# Port 80 should be ALLOW
```

### ❌ Styles not loading

Pages use CDN (Tailwind CSS, Lucide Icons). Ensure server has internet access.

### ❌ Wrong file permissions

```bash
sudo chown -R www-data:www-data /var/www/documind/
sudo chmod -R 755 /var/www/documind/
```

---

## File Checklist

Before deployment, ensure you have:

- [ ] index.html (included)
- [ ] login.html (included)
- [ ] admin.html (create from "Admin portal v0.2.txt")
- [ ] user.html (create from "Standard user v0.1.txt")

---

## Optional: Add Custom Domain & SSL

If you have a domain:

1. Point DNS A record to your server IP
2. Update Nginx config with domain name
3. Install free SSL:

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com
```

---

## Success! What's Next?

✅ Your DocuMind app is live  
✅ Both admin and users land on Search & Query page  
✅ No code changes needed  

The application uses:
- Client-side JavaScript only (no backend)
- CDN resources (Tailwind, Lucide Icons)
- Static HTML hosting

---

## Questions?

**Detailed guide:** Read `MANUAL_DEPLOYMENT.md`  
**Quick reference:** This file  
**Upload helper:** Run `./upload.sh`

**Need help?** Check the troubleshooting section above.

---

**© 2025 Cyber Base Limited. All rights reserved.**
