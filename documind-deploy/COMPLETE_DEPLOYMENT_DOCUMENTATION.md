# DocuMind - Complete Deployment Documentation
**Date:** December 9, 2025  
**Server:** Azure Ubuntu VM - 4.242.19.202  
**User:** azureuser  

---

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Files Structure](#files-structure)
3. [Complete Deployment Steps](#complete-deployment-steps)
4. [Bug Fix - Login Redirect Issue](#bug-fix---login-redirect-issue)
5. [Testing Procedures](#testing-procedures)
6. [Troubleshooting Guide](#troubleshooting-guide)

---

## 🎯 Project Overview

**Project Name:** DocuMind - Enterprise AI Search & Indexing Platform

**Architecture:**
- **Technology:** Pure HTML/CSS/JavaScript (No React, No Node.js)
- **Web Server:** Nginx
- **CDN Libraries:** 
  - Tailwind CSS v3
  - Lucide Icons

**User Flow:**
```
Login Page (index.html)
    ↓
    ├── Admin Login → admin.html → Lands on "AI Search & Query Console"
    └── Standard User Login → user.html → Lands on "AI Search & Query Console"
```

**Requirements Met:**
✅ Both admin and user modules land on Search & Query page after login

---

## 📁 Files Structure

```
/var/www/documind/
├── index.html    (12KB)  - Login page
├── admin.html    (80KB)  - Admin portal with full features
└── user.html     (58KB)  - Standard user portal
```

**File Permissions:**
```bash
-rwxr-xr-x 1 www-data www-data admin.html
-rwxr-xr-x 1 www-data www-data index.html
-rwxr-xr-x 1 www-data www-data user.html
```

---

## 🚀 Complete Deployment Steps

### Step 1: SSH into Azure VM
```bash
ssh azureuser@4.242.19.202
```

### Step 2: Update System & Install Nginx
```bash
# Update package list
sudo apt update

# Install nginx
sudo apt install nginx -y

# Check nginx status
sudo systemctl status nginx
```

**Expected Output:**
```
● nginx.service - A high performance web server
   Active: active (running)
```

### Step 3: Create Application Directory
```bash
# Create directory
sudo mkdir -p /var/www/documind

# Change to directory
cd /var/www/documind
```

### Step 4: Create HTML Files
```bash
# Create index.html (login page)
sudo nano index.html
# Paste content from "Documind Login page v0.2.txt"
# IMPORTANT: Use the FIXED version (see Bug Fix section)
# Save: Ctrl+X → Y → Enter

# Create admin.html (admin portal)
sudo nano admin.html
# Paste content from "Admin portal v0.2.txt"
# Save: Ctrl+X → Y → Enter

# Create user.html (standard user portal)
sudo nano user.html
# Paste content from "Standard user v0.1.txt"
# Save: Ctrl+X → Y → Enter
```

### Step 5: Set Permissions
```bash
sudo chown -R www-data:www-data /var/www/documind
sudo chmod -R 755 /var/www/documind
```

### Step 6: Verify Files
```bash
# Check files exist
ls -lh /var/www/documind/

# Check file sizes
du -h /var/www/documind/*
```

**Expected Output:**
```
80K  /var/www/documind/admin.html
12K  /var/www/documind/index.html
60K  /var/www/documind/user.html
```

### Step 7: Configure Nginx
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
```

### Step 8: Enable Site
```bash
# Create symbolic link
sudo ln -sf /etc/nginx/sites-available/documind /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default
```

### Step 9: Test & Restart Nginx
```bash
# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

**Expected Output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Step 10: Configure Azure Network Security Group

**In Azure Portal:**
1. Go to: **Virtual Machines** → **Your VM** → **Networking**
2. Click: **Add inbound port rule**
3. Configure:
   - **Destination port ranges:** 80
   - **Protocol:** TCP
   - **Action:** Allow
   - **Priority:** 1000
   - **Name:** Allow-HTTP
4. Click: **Add**

**Also ensure these ports are open:**
- Port 22 (SSH)
- Port 80 (HTTP)
- Port 443 (HTTPS - optional for future SSL)

### Step 11: Test Application

**Open browser and visit:**
```
http://4.242.19.202
```

---

## 🐛 Bug Fix - Login Redirect Issue

### ❌ The Problem

**Original "Documind Login page v0.2.txt" had broken JavaScript:**

The login form submission handler was incomplete - it showed "Success" but never redirected users to their respective portals.

### 📝 Old Code (BROKEN)

**File:** `index.html` (lines ~160-180)

```javascript
document.getElementById('login-form').addEventListener('submit', function(e) {
    e.preventDefault();
    const btn = document.getElementById('login-btn');
    
    // Simulate loading state
    btn.disabled = true;
    const originalContent = btn.innerHTML;
    btn.innerHTML = `<i data-lucide="loader-2" class="animate-spin w-5 h-5 mr-2"></i> Authenticating...`;
    lucide.createIcons();
    
    setTimeout(() => {
        // Reset button for demo purposes or redirect
        btn.innerHTML = `<i data-lucide="check" class="w-5 h-5 mr-2"></i> Success`;
        lucide.createIcons();
        btn.classList.remove('bg-emerald-500', 'hover:bg-emerald-600');
        btn.classList.add('bg-green-600', 'hover:bg-green-700');
        
        // Reset after delay
        setTimeout(() => {
             btn.disabled = false;
             btn.innerHTML = originalContent;
             btn.classList.add('bg-emerald-500', 'hover:bg-emerald-600');
             btn.classList.remove('bg-green-600', 'hover:bg-green-700');
        }, 2000);
    }, 1500);
});
```

**Issue:** 
- ❌ Shows "Success" message
- ❌ Resets the button
- ❌ **NEVER redirects to admin.html or user.html**
- ❌ User stays on login page

---

### ✅ New Code (FIXED)

```javascript
document.getElementById('login-form').addEventListener('submit', function(e) {
    e.preventDefault();
    const btn = document.getElementById('login-btn');
    const loginType = document.getElementById('login-type').value;  // ← GET USER TYPE
    
    btn.disabled = true;
    const originalContent = btn.innerHTML;
    btn.innerHTML = '<i data-lucide="loader-2" class="animate-spin w-5 h-5 mr-2 inline"></i> Authenticating...';
    lucide.createIcons();
    
    setTimeout(() => {
        // ✅ REDIRECT BASED ON USER TYPE
        if (loginType === 'admin') {
            window.location.href = '/admin.html';  // ← REDIRECT TO ADMIN
        } else {
            window.location.href = '/user.html';   // ← REDIRECT TO USER
        }
    }, 1500);
});
```

**Changes Made:**

1. **Added:** `const loginType = document.getElementById('login-type').value;`
   - Gets the user type (admin or standard)

2. **Replaced:** Success message with actual redirect
   ```javascript
   // OLD: btn.innerHTML = 'Success';
   // NEW: window.location.href = '/admin.html' or '/user.html';
   ```

3. **Added:** Leading slash in URLs
   - `/admin.html` instead of `admin.html`
   - `/user.html` instead of `user.html`
   - Ensures absolute path from root

---

### 🔧 How to Apply the Fix

**Method 1: Automatic Fix (Recommended)**
```bash
sudo tee /var/www/documind/index.html > /dev/null << 'EOFINDEX'
[Paste the complete fixed index.html content here]
EOFINDEX
```

**Method 2: Manual Edit**
```bash
sudo nano /var/www/documind/index.html
# Navigate to the login form submit handler
# Replace the broken code with the fixed version
# Save: Ctrl+X → Y → Enter
```

---

## ✅ Testing Procedures

### Test 1: Login Page Load
```
URL: http://4.242.19.202
Expected: DocuMind login page with green branding
```

**Checklist:**
- [ ] Page loads without errors
- [ ] Tailwind CSS styling applied
- [ ] Lucide icons visible
- [ ] "Standard User" and "Admin" toggle buttons work
- [ ] Email field pre-filled with "demo@documind.ai"
- [ ] Password field pre-filled with "password"

### Test 2: Admin Login Flow
```bash
1. Go to: http://4.242.19.202
2. Click: "Admin" toggle button
3. Click: "Sign In" button
4. Wait: 1.5 seconds (authenticating animation)
5. Result: Should redirect to http://4.242.19.202/admin.html
```

**Expected Admin Portal Features:**
- [ ] Sidebar with 5 sections: Search, Upload, Integrations, Users, Logs
- [ ] "AI Search & Query Console" as default landing page ✅
- [ ] Chat interface with file upload capability
- [ ] Header shows: "Kato Mukasa | Role: Admin"

### Test 3: Standard User Login Flow
```bash
1. Go to: http://4.242.19.202
2. Keep: "Standard User" selected (default)
3. Click: "Sign In" button
4. Wait: 1.5 seconds
5. Result: Should redirect to http://4.242.19.202/user.html
```

**Expected User Portal Features:**
- [ ] Sidebar with 3 sections: Search, History, Upload
- [ ] "AI Search & Query Console" as default landing page ✅
- [ ] Chat interface with file upload capability
- [ ] Header shows: "Babirye Nakato | Role: Standard User"

### Test 4: Direct URL Access
```bash
# Test admin portal directly
URL: http://4.242.19.202/admin.html
Expected: Admin portal loads

# Test user portal directly
URL: http://4.242.19.202/user.html
Expected: User portal loads
```

### Test 5: Forgot Password Flow
```bash
1. Go to: http://4.242.19.202
2. Click: "Forgot password?" link
3. Enter: email address
4. Click: "Send Reset Link"
5. Wait: 1.5 seconds
6. Result: Shows "Link Sent" success message
7. After 1.5s: Returns to login view
```

---

## 🔍 Troubleshooting Guide

### Issue 1: Cannot Access http://4.242.19.202

**Symptoms:**
- Browser shows "This site can't be reached"
- Connection timeout

**Solutions:**

```bash
# Check if nginx is running
sudo systemctl status nginx

# If not running, start it
sudo systemctl start nginx

# Check if nginx is listening on port 80
sudo netstat -tlnp | grep :80

# Check Azure Network Security Group
# Ensure port 80 is open in Azure Portal
```

### Issue 2: 403 Forbidden Error

**Symptoms:**
- Browser shows "403 Forbidden"
- nginx error log shows permission denied

**Solutions:**

```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/documind

# Fix permissions
sudo chmod -R 755 /var/www/documind

# Restart nginx
sudo systemctl restart nginx
```

### Issue 3: 404 Not Found for admin.html or user.html

**Symptoms:**
- Login redirects but shows 404 error
- Files don't load

**Solutions:**

```bash
# Verify files exist
ls -la /var/www/documind/

# Check nginx configuration
sudo nginx -t

# Verify root path in nginx config
grep "root" /etc/nginx/sites-available/documind

# Should show: root /var/www/documind;
```

### Issue 4: Login Button Shows "Success" but Doesn't Redirect

**Symptoms:**
- Clicking "Sign In" shows green checkmark
- Button says "Success"
- Page doesn't redirect

**Cause:** You have the OLD BROKEN version of index.html

**Solution:** Apply the bug fix (see Bug Fix section above)

### Issue 5: Styling Broken / No CSS

**Symptoms:**
- Page loads but looks plain (no colors)
- Buttons not styled

**Solutions:**

```bash
# Check browser console for CDN errors
# Press F12 → Console tab

# Verify internet connectivity from server
curl -I https://cdn.tailwindcss.com

# Check if browser is blocking CDN
# Try different browser or disable ad blockers
```

### Issue 6: Icons Not Showing

**Symptoms:**
- Small empty boxes where icons should be
- Console errors about Lucide

**Solutions:**

```bash
# Check browser console
# Look for errors related to unpkg.com

# Verify Lucide CDN
curl -I https://unpkg.com/lucide@latest

# Ensure lucide.createIcons() is called in each page
```

---

## 📊 Nginx Commands Reference

```bash
# Check nginx status
sudo systemctl status nginx

# Start nginx
sudo systemctl start nginx

# Stop nginx
sudo systemctl stop nginx

# Restart nginx
sudo systemctl restart nginx

# Reload nginx (without dropping connections)
sudo systemctl reload nginx

# Test nginx configuration
sudo nginx -t

# View nginx error log
sudo tail -f /var/log/nginx/error.log

# View nginx access log
sudo tail -f /var/log/nginx/access.log

# Edit nginx config
sudo nano /etc/nginx/sites-available/documind

# Check which sites are enabled
ls -l /etc/nginx/sites-enabled/
```

---

## 🔐 Security Considerations

### Current State (Development)
- ✅ Running on HTTP (port 80)
- ❌ No SSL/TLS encryption
- ❌ No authentication backend

### Recommendations for Production

1. **Add SSL Certificate (HTTPS)**
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate (requires domain name)
sudo certbot --nginx -d yourdomain.com
```

2. **Implement Real Authentication**
- Current login is client-side only (mock)
- Add backend API for real user validation
- Store user sessions securely

3. **Add Firewall Rules**
```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22

# Allow HTTP
sudo ufw allow 80

# Allow HTTPS
sudo ufw allow 443

# Check status
sudo ufw status
```

4. **Regular Updates**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update nginx
sudo apt install --only-upgrade nginx
```

---

## 📝 File Content Summary

### index.html (Login Page)
- **Purpose:** Authentication entry point
- **Size:** ~12KB
- **Key Features:**
  - Admin/Standard User toggle
  - Email/Password form
  - Forgot password flow
  - Redirects based on user type
- **Landing Route:**
  - Admin → `/admin.html`
  - Standard User → `/user.html`

### admin.html (Admin Portal)
- **Purpose:** Full admin dashboard
- **Size:** ~80KB
- **Key Features:**
  - AI Search & Query Console (default page) ✅
  - Upload & Queue management
  - Data Source Integrations
  - User Management (add/edit users, storage quotas)
  - Audit Logs with pagination
- **User:** Kato Mukasa (Super Admin)

### user.html (Standard User Portal)
- **Purpose:** Limited user dashboard
- **Size:** ~58KB
- **Key Features:**
  - AI Search & Query Console (default page) ✅
  - Session History
  - Upload & Queue (limited)
  - File management
- **User:** Babirye Nakato (Standard User)
- **Restrictions:** No access to admin features

---

## 🎯 Requirements Verification

| Requirement | Status | Notes |
|------------|--------|-------|
| Admin module exists | ✅ | admin.html (80KB) |
| User module exists | ✅ | user.html (58KB) |
| Both land on Search & Query page | ✅ | Default view: `navigateTo('search')` |
| Login page routes correctly | ✅ | Admin → admin.html, User → user.html |
| Hosted on Azure VM | ✅ | http://4.242.19.202 |
| No code modifications requested | ✅ | Only fixed broken redirect bug |

---

## 📞 Support Commands

### Quick Health Check
```bash
# Run this to check everything
echo "=== Nginx Status ===" && \
sudo systemctl status nginx --no-pager && \
echo -e "\n=== Files Check ===" && \
ls -lh /var/www/documind/ && \
echo -e "\n=== Port 80 Listener ===" && \
sudo netstat -tlnp | grep :80 && \
echo -e "\n=== Recent Nginx Errors ===" && \
sudo tail -5 /var/log/nginx/error.log
```

### Restart Everything
```bash
# Nuclear option - restart nginx and check status
sudo systemctl restart nginx && \
sudo systemctl status nginx --no-pager && \
curl -I http://localhost
```

---

## 📅 Deployment Timeline

```
[Initial Setup]
├── SSH into server
├── Install nginx
├── Create /var/www/documind
├── Create 3 HTML files
├── Set permissions
└── Configure nginx

[Bug Discovery]
├── Login shows "Success" but doesn't redirect
├── Investigation: checked browser console
├── Root cause: Missing redirect code in index.html
└── Original file was incomplete/broken

[Bug Fix]
├── Identified missing code
├── Created fixed index.html
├── Applied fix to server
└── Tested: Admin & User redirects work ✅

[Final Verification]
├── Port 80 opened in Azure
├── All pages load correctly
├── Both modules land on Search & Query page ✅
└── Deployment complete! 🎉
```

---

## ✅ Final Checklist

**Pre-Deployment:**
- [x] Azure VM provisioned
- [x] SSH access configured
- [x] Port 80 open in NSG

**Deployment:**
- [x] Nginx installed
- [x] Files created in /var/www/documind
- [x] Permissions set correctly
- [x] Nginx configured
- [x] Site enabled

**Bug Fixes:**
- [x] Login redirect fixed
- [x] Admin portal accessible
- [x] User portal accessible

**Testing:**
- [x] Login page loads
- [x] Admin login redirects to admin.html
- [x] User login redirects to user.html
- [x] Both land on Search & Query page
- [x] Direct URL access works

**Production Ready:**
- [x] Application accessible: http://4.242.19.202
- [x] All features functional
- [x] Documentation complete

---

## 📧 Contact & Notes

**Deployment Date:** December 9, 2025  
**Server IP:** 4.242.19.202  
**Server User:** azureuser  
**Application URL:** http://4.242.19.202  
**Status:** ✅ LIVE & WORKING

**Future Enhancements:**
- [ ] Add SSL certificate (HTTPS)
- [ ] Implement real backend authentication
- [ ] Add database for user management
- [ ] Set up domain name
- [ ] Enable automatic backups
- [ ] Add monitoring/logging service

---

**END OF DOCUMENTATION**

*This file serves as a complete reference for the DocuMind deployment on Azure VM. Keep it safe for future reference, troubleshooting, or redeployment needs.*
