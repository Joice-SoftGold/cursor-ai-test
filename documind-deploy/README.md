# DocuMind Deployment Guide

## Files in this folder:
1. **index.html** - Login page (landing page)
2. **admin.html** - Admin portal (after admin login)
3. **user.html** - Standard user portal (after user login)
4. **deploy.sh** - Automated deployment script

## Quick Deployment Steps:

### Step 1: Upload files to your Azure VM
From your LOCAL machine terminal, run:

```bash
scp -r /workspace/documind-deploy/* azureuser@4.242.19.202:/home/azureuser/
```

### Step 2: SSH into your server
```bash
ssh azureuser@4.242.19.202
```

### Step 3: Run the deployment script
```bash
cd /home/azureuser
chmod +x deploy.sh
sudo ./deploy.sh
```

### Step 4: Open port 80 in Azure Portal
1. Go to Azure Portal → Your VM → Networking
2. Add inbound rule: Port 80, TCP, Allow

### Step 5: Access your app
Open browser: http://4.242.19.202

## Manual Deployment (if script fails):

```bash
# Install nginx
sudo apt update && sudo apt install nginx -y

# Copy files
sudo mkdir -p /var/www/documind
sudo cp *.html /var/www/documind/
sudo chown -R www-data:www-data /var/www/documind

# Configure nginx
sudo tee /etc/nginx/sites-available/documind << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    root /var/www/documind;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINXEOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```
