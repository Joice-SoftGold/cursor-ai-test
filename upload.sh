#!/bin/bash

# Simple upload script for DocuMind files to Azure Ubuntu Server

echo "=================================================="
echo "  DocuMind - Upload to Azure Ubuntu Server"
echo "=================================================="
echo ""

# Ask for server details
read -p "Enter your SSH key path (e.g., ~/Downloads/mykey.pem): " SSH_KEY
read -p "Enter your server IP address: " SERVER_IP
read -p "Enter your SSH username (default: azureuser): " SSH_USER
SSH_USER=${SSH_USER:-azureuser}

echo ""
echo "Setting SSH key permissions..."
chmod 400 "$SSH_KEY"

echo "Uploading HTML files..."
scp -i "$SSH_KEY" index.html login.html admin.html user.html "$SSH_USER@$SERVER_IP:/tmp/"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Files uploaded successfully!"
    echo ""
    echo "Now SSH into your server and run:"
    echo "  ssh -i $SSH_KEY $SSH_USER@$SERVER_IP"
    echo ""
    echo "Then move files to web directory:"
    echo "  sudo mv /tmp/*.html /var/www/documind/"
    echo "  sudo chown -R www-data:www-data /var/www/documind/"
    echo ""
    echo "Visit: http://$SERVER_IP"
else
    echo ""
    echo "✗ Upload failed. Check your SSH key and server IP."
fi
