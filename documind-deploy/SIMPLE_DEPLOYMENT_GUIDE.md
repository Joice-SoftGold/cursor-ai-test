# DocuMind - Simple Deployment Guide

## YOU ARE HERE: Files are too large to create via terminal

### EASIEST METHOD: Direct File Creation on Server

Since the HTML files are very large (especially admin.html with 50KB+), here's the simplest approach:

---

## Step-by-Step Instructions:

### STEP 1: On Your Azure Server (SSH Terminal)

```bash
# Install nginx first
sudo apt update
sudo apt install nginx -y

# Create directory
sudo mkdir -p /var/www/documind
cd /var/www/documind
```

### STEP 2: Create the 3 HTML Files Directly

**Option A: Use nano editor (recommended)**
```bash
# Create index.html (login page)
sudo nano index.html
# Paste the content from "Documind Login page v0.2.txt"
# Press: Ctrl+X, then Y, then Enter to save

# Create admin.html (admin portal)
sudo nano admin.html
# Paste the content from "Admin portal v0.2.txt"
# Press: Ctrl+X, then Y, then Enter to save

# Create user.html (standard user portal)
sudo nano user.html
# Paste the content from "Standard user v0.1.txt"
# Press: Ctrl+X, then Y, then Enter to save
```

**Option B: Use vim editor**
```bash
# For each file:
sudo vim index.html
# Press 'i' to enter insert mode
# Paste content
# Press ESC, then type :wq and press Enter

# Repeat for admin.html and user.html
```

### STEP 3: Set Permissions
```bash
sudo chown -R www-data:www-data /var/www/documind
sudo chmod -R 755 /var/www/documind
```

### STEP 4: Configure Nginx
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

# Enable the site
sudo ln -sf /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### STEP 5: Open Port 80 in Azure Portal

1. Go to **Azure Portal**
2. Navigate to your **Virtual Machine**
3. Click **Networking** (left sidebar)
4. Click **Add inbound port rule**
5. Set:
   - **Destination port ranges**: 80
   - **Protocol**: TCP
   - **Action**: Allow
   - **Priority**: 1000
   - **Name**: Allow-HTTP
6. Click **Add**

### STEP 6: Test Your Application

Open browser and visit:
```
http://4.242.19.202
```

You should see the DocuMind login page!

---

## Alternative: Use SCP from Your Local Machine

If you have the 3 HTML files saved on your local computer:

```bash
# From your local machine terminal:
scp index.html admin.html user.html azureuser@4.242.19.202:/home/azureuser/

# Then SSH into server:
ssh azureuser@4.242.19.202

# Move files:
sudo mkdir -p /var/www/documind
sudo mv ~/index.html ~/admin.html ~/user.html /var/www/documind/
sudo chown -R www-data:www-data /var/www/documind

# Then continue from STEP 4 above
```

---

## Troubleshooting

**Check if nginx is running:**
```bash
sudo systemctl status nginx
```

**View nginx error logs:**
```bash
sudo tail -f /var/log/nginx/error.log
```

**Check if files exist:**
```bash
ls -lh /var/www/documind/
```

**Test from server itself:**
```bash
curl http://localhost
```

---

## File Names Summary
- `index.html` = Login page (from "Documind Login page v0.2.txt")
- `admin.html` = Admin portal (from "Admin portal v0.2.txt")
- `user.html` = User portal (from "Standard user v0.1.txt")

Both admin and user should land on search & query page after login ✓
