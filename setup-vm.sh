#!/bin/bash

# VM Setup Script - Run this after SSH into your Azure VM
# This installs Node.js, npm, and sets up the development environment

set -e  # Exit on any error

echo "=========================================="
echo "Starting VM Setup for Frontend Development"
echo "=========================================="

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Node.js 20.x LTS
echo "📥 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install build essentials (needed for some npm packages)
echo "🔧 Installing build tools..."
sudo apt-get install -y build-essential git curl

# Verify installations
echo ""
echo "✅ Installation Complete!"
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""

# Create project directory
echo "📁 Creating project directory..."
mkdir -p ~/frontend-project
cd ~/frontend-project

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. cd ~/frontend-project"
echo "2. Run: npm create vite@latest my-app -- --template react"
echo "3. Upload your component.txt file"
echo "4. Run the deploy script"
echo ""
