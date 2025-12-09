# DocuMind - Manual Deployment to Azure Ubuntu Server

## Step 1: SSH Connection Setup

### On Your Local Machine

1. **Locate your SSH private key** (the .pem or .key file you downloaded when creating the VM)
   ```bash
   # Example: your key might be in Downloads
   ls ~/Downloads/*.pem
   ```

2. **Set correct permissions on your SSH key** (chmod)
   ```bash
   chmod 400 ~/path/to/your-key.pem
   ```
   
   ⚠️ **Important**: The key file must have restricted permissions (400) or SSH will refuse to use it.

3. **Connect to your Ubuntu server**
   ```bash
   ssh -i ~/path/to/your-key.pem azureuser@YOUR_SERVER_IP
   ```
   
   Replace:
   - `~/path/to/your-key.pem` with your actual key path
   - `YOUR_SERVER_IP` with your Azure VM's public IP address
   - `azureuser` with your VM's username (might be different)

### Find Your VM's Public IP

In Azure Portal:
- Go to your Virtual Machine
- Look for "Public IP address" on the overview page

OR use Azure CLI:
```bash
az vm list-ip-addresses --resource-group YOUR_RG_NAME --name YOUR_VM_NAME --output table
```

---

## Step 2: Install Web Server on Ubuntu

Once connected via SSH to your Ubuntu server:

### Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### Option A: Install Nginx (Recommended - Lightweight)

```bash
# Install Nginx
sudo apt install nginx -y

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

### Option B: Install Apache (Alternative)

```bash
# Install Apache
sudo apt install apache2 -y

# Start and enable Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Check status
sudo systemctl status apache2
```

**I recommend Nginx** - it's faster and lighter for static sites.

---

## Step 3: Configure Firewall & Azure Network Security

### On Ubuntu Server (UFW Firewall)

```bash
# Allow SSH (if not already allowed)
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS (for future SSL)
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### In Azure Portal

1. Go to your VM → **Networking** → **Network Security Group**
2. Add inbound port rules:
   - **HTTP**: Port 80 (TCP)
   - **HTTPS**: Port 443 (TCP)
   - **SSH**: Port 22 (TCP) - should already exist

---

## Step 4: Deploy DocuMind Files

### Create Website Directory

```bash
# For Nginx (default web root)
sudo mkdir -p /var/www/documind

# Set permissions
sudo chown -R $USER:$USER /var/www/documind
sudo chmod -R 755 /var/www/documind
```

### Configure Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/documind
```

Paste this configuration:

```nginx
server {
    listen 80;
    listen [::]:80;
    
    server_name YOUR_SERVER_IP;  # Replace with your IP or domain
    
    root /var/www/documind;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Enable gzip compression
    gzip on;
    gzip_types text/html text/css application/javascript;
}
```

Save and exit (Ctrl+O, Enter, Ctrl+X)

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

## Step 5: Upload HTML Files to Server

### Option A: Using SCP (From Your Local Machine)

```bash
# Upload all HTML files at once
scp -i ~/path/to/your-key.pem index.html login.html admin.html user.html azureuser@YOUR_SERVER_IP:/tmp/

# Then on the server, move them:
ssh -i ~/path/to/your-key.pem azureuser@YOUR_SERVER_IP
sudo mv /tmp/*.html /var/www/documind/
```

### Option B: Using SFTP (Interactive)

```bash
sftp -i ~/path/to/your-key.pem azureuser@YOUR_SERVER_IP

# Once connected:
put index.html
put login.html  
put admin.html
put user.html
exit

# Move files on server:
sudo mv /home/azureuser/*.html /var/www/documind/
```

### Option C: Using Git (If files are in GitHub)

On the server:
```bash
# Install git
sudo apt install git -y

# Clone your repository
cd /tmp
git clone https://github.com/your-username/your-repo.git

# Copy HTML files
sudo cp your-repo/*.html /var/www/documind/
```

### Option D: Copy-Paste (For small files)

```bash
# On server, create each file
sudo nano /var/www/documind/index.html
# Paste content, save with Ctrl+O, Enter, Ctrl+X

# Repeat for other files
sudo nano /var/www/documind/login.html
sudo nano /var/www/documind/admin.html
sudo nano /var/www/documind/user.html
```

---

## Step 6: Set Correct Permissions

```bash
# On the server
sudo chown -R www-data:www-data /var/www/documind
sudo chmod -R 755 /var/www/documind
```

---

## Step 7: Test Your Website

Open your browser and visit:
```
http://YOUR_SERVER_IP
```

You should see the DocuMind login page!

Test all pages:
- `http://YOUR_SERVER_IP/login.html`
- `http://YOUR_SERVER_IP/admin.html`
- `http://YOUR_SERVER_IP/user.html`

---

## Quick Reference Commands

### SSH Connection
```bash
chmod 400 ~/path/to/your-key.pem
ssh -i ~/path/to/your-key.pem azureuser@YOUR_SERVER_IP
```

### Upload Files
```bash
scp -i ~/path/to/your-key.pem *.html azureuser@YOUR_SERVER_IP:/tmp/
```

### Check Nginx Status
```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
sudo systemctl reload nginx  # Reload after changes
```

### View Nginx Logs
```bash
sudo tail -f /var/log/nginx/access.log  # Access logs
sudo tail -f /var/log/nginx/error.log   # Error logs
```

---

## Troubleshooting

### Can't SSH?
```bash
# Check if SSH key permissions are correct
ls -l ~/path/to/your-key.pem  # Should show -r--------

# If not, fix it:
chmod 400 ~/path/to/your-key.pem
```

### Nginx won't start?
```bash
# Check configuration
sudo nginx -t

# Check logs
sudo journalctl -u nginx -n 50
```

### Can't access website?
1. Check Azure NSG rules (port 80 must be open)
2. Check Ubuntu firewall: `sudo ufw status`
3. Check Nginx is running: `sudo systemctl status nginx`
4. Check files exist: `ls -la /var/www/documind/`

### Permission denied errors?
```bash
sudo chown -R www-data:www-data /var/www/documind
sudo chmod -R 755 /var/www/documind
```

---

## Optional: Add Custom Domain & SSL

If you have a domain name:

1. **Point your domain to the server IP** (in your DNS provider)

2. **Install Certbot for free SSL**
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   sudo certbot --nginx -d yourdomain.com
   ```

---

## Summary

1. ✅ `chmod 400` your SSH key
2. ✅ SSH into your Ubuntu server
3. ✅ Install Nginx web server
4. ✅ Configure firewall (UFW + Azure NSG)
5. ✅ Upload HTML files via SCP
6. ✅ Configure Nginx to serve the files
7. ✅ Access via `http://YOUR_SERVER_IP`

Need help with any specific step? Let me know!
