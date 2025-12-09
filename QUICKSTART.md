# Quick Start Guide - Deploy DocuMind to Your Azure Ubuntu Server

## Files in This Directory

- ✅ `index.html` - Redirects to login page  
- ✅ `login.html` - Login page with admin/user selection
- ⚠️ `admin.html` - **YOU NEED TO CREATE THIS** (instructions below)
- ⚠️ `user.html` - **YOU NEED TO CREATE THIS** (instructions below)
- 📄 `MANUAL_DEPLOYMENT.md` - Complete deployment instructions
- 📄 `upload.sh` - Script to upload files to your server

---

## Before You Start

### Create the Missing HTML Files

You have the content in your text files. Create them like this:

**On Windows:**
```powershell
# Create admin.html
Copy-Item "Admin portal v0.2.txt" -Destination admin.html

# Create user.html  
Copy-Item "Standard user v0.1.txt" -Destination user.html
```

**On Mac/Linux:**
```bash
# Create admin.html
cp "Admin portal v0.2.txt" admin.html

# Create user.html
cp "Standard user v0.1.txt" user.html
```

**OR** manually:
1. Open "Admin portal v0.2.txt" in a text editor
2. Save it as `admin.html` in this directory
3. Open "Standard user v0.1.txt" in a text editor  
4. Save it as `user.html` in this directory

---

## Quick Deploy Steps

### 1. Set Up SSH Key (On Your Local Machine)

```bash
# Fix permissions on your SSH key
chmod 400 ~/path/to/your-key.pem
```

### 2. Connect to Your Ubuntu Server

```bash
ssh -i ~/path/to/your-key.pem azureuser@YOUR_SERVER_IP
```

Replace:
- `~/path/to/your-key.pem` - your actual key path
- `YOUR_SERVER_IP` - your Azure VM's public IP
- `azureuser` - your username (if different)

### 3. Install Nginx (On the Server)

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 4. Configure Firewall (On the Server)

```bash
# Ubuntu firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Also open port 80 in Azure Portal:
# VM → Networking → Add inbound port rule → Port 80
```

### 5. Create Website Directory (On the Server)

```bash
sudo mkdir -p /var/www/documind
sudo chown -R $USER:$USER /var/www/documind
sudo chmod -R 755 /var/www/documind
```

### 6. Configure Nginx (On the Server)

```bash
sudo nano /etc/nginx/sites-available/documind
```

Paste this (replace YOUR_SERVER_IP):

```nginx
server {
    listen 80;
    server_name YOUR_SERVER_IP;
    root /var/www/documind;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

Save (Ctrl+O, Enter) and exit (Ctrl+X), then:

```bash
sudo ln -s /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 7. Upload Files (From Your Local Machine)

**Option A - Use the upload script:**
```bash
./upload.sh
```

**Option B - Manual upload:**
```bash
scp -i ~/path/to/your-key.pem index.html login.html admin.html user.html azureuser@YOUR_SERVER_IP:/tmp/
```

Then on the server:
```bash
sudo mv /tmp/*.html /var/www/documind/
sudo chown -R www-data:www-data /var/www/documind/
```

### 8. Visit Your Website

Open browser and go to:
```
http://YOUR_SERVER_IP
```

You should see the DocuMind login page! 🎉

---

## Default Login Credentials (Demo)

- **Email:** demo@documind.ai
- **Password:** password

After login:
- **Admin** → Lands on Search & Query page (admin.html)
- **Standard User** → Lands on Search & Query page (user.html)

---

## Troubleshooting

### Can't connect via SSH?

```bash
# Check key permissions
ls -l ~/path/to/your-key.pem
# Should show: -r--------

# Fix if needed:
chmod 400 ~/path/to/your-key.pem
```

### Website not loading?

1. Check Nginx is running:
   ```bash
   sudo systemctl status nginx
   ```

2. Check files exist:
   ```bash
   ls -la /var/www/documind/
   ```

3. Check Azure NSG (Network Security Group):
   - Azure Portal → Your VM → Networking
   - Port 80 must be open for inbound traffic

4. Check Ubuntu firewall:
   ```bash
   sudo ufw status
   ```

### Page shows but styles broken?

The pages use CDN resources (Tailwind CSS, Lucide Icons). Make sure your server has internet access.

---

## Need More Details?

Read the complete guide: **MANUAL_DEPLOYMENT.md**

---

## Summary Checklist

- [ ] Created admin.html from "Admin portal v0.2.txt"
- [ ] Created user.html from "Standard user v0.1.txt"  
- [ ] Fixed SSH key permissions (chmod 400)
- [ ] Connected to Ubuntu server via SSH
- [ ] Installed Nginx
- [ ] Configured firewall (UFW + Azure NSG)
- [ ] Created /var/www/documind directory
- [ ] Configured Nginx site
- [ ] Uploaded all 4 HTML files
- [ ] Set correct permissions (www-data)
- [ ] Tested website in browser

**Result:** Your DocuMind application is now live on Azure! 🚀
