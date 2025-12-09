#!/bin/bash

echo "======================================"
echo "DocuMind Deployment Script"
echo "======================================"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    echo "✓ Running with sudo privileges"
else
    echo "✗ Please run with sudo: sudo ./deploy.sh"
    exit 1
fi

# Step 1: Install nginx
echo ""
echo "[1/6] Installing nginx..."
apt update -qq
apt install nginx -y > /dev/null 2>&1
echo "✓ Nginx installed"

# Step 2: Create directory
echo "[2/6] Creating /var/www/documind..."
mkdir -p /var/www/documind
echo "✓ Directory created"

# Step 3: Copy HTML files
echo "[3/6] Copying HTML files..."
if [ -f "index.html" ] && [ -f "admin.html" ] && [ -f "user.html" ]; then
    cp index.html admin.html user.html /var/www/documind/
    echo "✓ Files copied"
else
    echo "✗ ERROR: HTML files not found in current directory!"
    exit 1
fi

# Step 4: Set permissions
echo "[4/6] Setting permissions..."
chown -R www-data:www-data /var/www/documind
chmod -R 755 /var/www/documind
echo "✓ Permissions set"

# Step 5: Configure nginx
echo "[5/6] Configuring nginx..."
cat > /etc/nginx/sites-available/documind << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    root /var/www/documind;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Disable caching for development
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}
NGINXEOF

ln -sf /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
echo "✓ Nginx configured"

# Step 6: Test and restart nginx
echo "[6/6] Testing and restarting nginx..."
if nginx -t > /dev/null 2>&1; then
    systemctl restart nginx
    echo "✓ Nginx restarted successfully"
else
    echo "✗ Nginx configuration test failed"
    nginx -t
    exit 1
fi

echo ""
echo "======================================"
echo "✓ Deployment Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Open port 80 in Azure Portal (Networking → Inbound rules)"
echo "2. Access your app at: http://4.242.19.202"
echo ""
echo "To check status: sudo systemctl status nginx"
echo "To view logs: sudo tail -f /var/log/nginx/error.log"
echo ""
